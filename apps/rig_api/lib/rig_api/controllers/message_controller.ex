defmodule RigApi.MessageController do
  require Logger

  use RigApi, :controller
  use PhoenixSwagger

  alias Plug.Conn

  alias Rig.EventFilter
  alias RIG.Plug.BodyReader
  alias RigAuth.AuthorizationCheck.Submission
  alias RigCloudEvents.CloudEvent
  alias RigCloudEvents.PlugUtils
  alias RigInboundGatewayWeb.MediaTypeHandling

  action_fallback(RigApi.FallbackController)

  swagger_path :create do
    post("/v1/messages")
    summary("Submit an event, to be forwarded to subscribed frontends.")
    description("Allows you to submit a single event to RIG using a simple, \
    synchronous call. While for production setups we recommend ingesting events \
    asynchronously (e.g., via a Kafka topic), using this endpoint can be simple \
    alternative during development or for low-traffic production setups.")

    parameters do
      messageBody(
        :body,
        Schema.ref(:CloudEvent),
        "CloudEvent",
        required: true
      )
    end

    response(202, "Accepted - message queued for transport")
    response(400, "Bad Request: Failed to parse request body :parse-error")
  end

  @doc """
  Accepts message to be sent to front-ends.
  """
  def publish(%{method: "POST"} = conn, _params) do
    PlugUtils.handle_cloudevent(conn,
      binary: &handle_binary_mode/1,
      structured: &handle_structured_mode/1
    )
  end

  # ---

  # The spec about binary mode:
  #
  # > The binary content mode accommodates any shape of event data, and allows for
  # > efficient transfer and without transcoding effort. The HTTP Content-Type value
  # > maps directly to the CloudEvents datacontenttype attribute. The context attributes
  # > are sent in the header.
  #
  # Well not so efficient in our case, since we have to transcode everything anyway..
  defp handle_binary_mode(conn) do
    with ["0.2"] <- Conn.get_req_header(conn, "ce-specversion") do
      {conn, json} = build_cloudevent_json(conn)

      json
      |> CloudEvent.parse()
      |> case do
        {:ok, cloud_event} ->
          handle_event(conn, cloud_event)

        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> text("""
          Your request looks like it's using the CloudEvents binary content mode \
          but can't be parsed (#{inspect(reason)}). Please make sure you're \
          passing the headers according to the spec:

          HTTP Transport Binding for CloudEvents
          https://github.com/cloudevents/spec/blob/master/http-transport-binding.md

          Request headers:
          #{for {k, v} <- conn.req_headers, into: "", do: "  #{k}: #{v}\n"}
          """)
      end
    else
      ce_specversion_headers ->
        conn
        |> put_status(:bad_request)
        |> text("""
        Your request looks like it's using the CloudEvents binary content mode, \
        but the ce-specversion header is #{inspect(ce_specversion_headers)} \
        instead of [\"0.2\"].\
        """)
    end
  end

  # ---

  defp build_cloudevent_json(conn) do
    event =
      conn.req_headers
      |> Enum.filter(fn {k, _} ->
        k in [
          "content-type",
          "ce-specversion",
          "ce-type",
          "ce-source",
          "ce-id",
          "ce-time",
          "ce-schemaurl"
        ]
      end)
      |> Enum.into(%{}, fn
        # Strip "ce-" prefix:
        {"ce-" <> k, v} -> {k, v}
        # Use HTTP content type:
        {"content-type", v} -> {"contenttype", v}
      end)

    {:ok, body, conn} = BodyReader.read_full_body(conn)

    event =
      case MediaTypeHandling.media_type(event["contenttype"]) do
        {"application", "json"} ->
          # Decoding the body allows to use fields in `data` in subscriptions:
          event
          |> Map.put("data", Jason.decode!(body))
          |> Map.delete("contenttype")

        _ ->
          event
          |> Map.put("data", body)
      end

    {conn, Jason.encode!(event)}
  end

  # ---

  # The spec about structured mode:
  #
  # > The structured content mode keeps event metadata and data together in the payload,
  # > allowing simple forwarding of the same event across multiple routing hops, and
  # > across multiple transports.
  defp handle_structured_mode(conn) do
    with {:ok, json, conn} <- BodyReader.read_full_body(conn),
         {:ok, cloud_event} <- CloudEvent.parse(json) do
      handle_event(conn, cloud_event)
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> text("The request body does not look like a CloudEvent: #{inspect(reason)}")
    end
  end

  # ---

  defp handle_event(conn, %CloudEvent{} = cloud_event) do
    with :ok <- Submission.check_authorization(conn, cloud_event) do
      :ok = EventFilter.forward_event(cloud_event)

      conn
      |> put_status(:accepted)
      |> json(cloud_event.json)
    else
      {:error, :not_authorized} ->
        conn |> put_status(:forbidden) |> text("Submission denied.")

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> text("Failed to parse request body: #{inspect(reason)}")
    end
  end

  # ---

  def swagger_definitions do
    %{
      CloudEvent:
        swagger_schema do
          title("CloudEvent")
          description("The broadcasted CloudEvent according to the CloudEvents spec.")

          properties do
            id(
              :string,
              "ID of the event. The semantics of this string are explicitly undefined to ease \
              the implementation of producers. Enables deduplication.",
              required: true,
              example: "A database commit ID"
            )

            specversion(
              :string,
              "The version of the CloudEvents specification which the event uses. This \
              enables the interpretation of the context. Compliant event producers \
              MUST use a value of 0.2 when referring to this version of the \
              specification.",
              required: true,
              example: "0.2"
            )

            source(
              :string,
              "This describes the event producer. Often this will include information such \
              as the type of the event source, the organization publishing the event, the \
              process that produced the event, and some unique identifiers. The exact syntax \
              and semantics behind the data encoded in the URI is event producer defined.",
              required: true,
              example: "/cloudevents/spec/pull/123"
            )

            type(
              :string,
              "Type of occurrence which has happened. Often this attribute is used for \
              routing, observability, policy enforcement, etc.",
              required: true,
              example: "com.example.object.delete.v2"
            )
          end
        end
    }
  end
end
