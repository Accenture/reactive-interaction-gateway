defmodule RigInboundGatewayWeb.V1.EventController do
  @moduledoc """
  Publish a CloudEvent.
  """
  require Logger
  use Rig.Config, [:cors]

  use RigInboundGatewayWeb, :controller

  alias Plug.Conn

  alias Rig.EventFilter
  alias RIG.Plug.BodyReader
  alias RigAuth.AuthorizationCheck.Submission
  alias RigCloudEvents.CloudEvent
  alias RigCloudEvents.PlugUtils
  alias RigInboundGatewayWeb.MediaTypeHandling
  alias RigOutboundGateway

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "POST")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> send_resp(:no_content, "")
  end

  # ---

  defp with_allow_origin(conn) do
    %{cors: origins} = config()
    put_resp_header(conn, "access-control-allow-origin", origins)
  end

  # ---

  @doc "Plug action to send a CloudEvent to subscribers."
  def publish(%{method: "POST"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> PlugUtils.handle_cloudevent(
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
    content_type = MediaTypeHandling.content_type(conn)

    json? =
      case content_type do
        {"application", "json"} -> true
        {"application", "cloudevents+json"} -> true
        _ -> false
      end

    if json? do
      with {:ok, json, conn} <- BodyReader.read_full_body(conn),
           {:ok, cloud_event} <-
             CloudEvent.parse(json) do
        handle_event(conn, cloud_event)
      else
        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> text("The request body does not look like a CloudEvent: #{inspect(reason)}")
      end
    else
      conn
      |> put_status(:unsupported_media_type)
      |> text(
        "The given content-type #{inspect(content_type)} is currently not supported for structured mode."
      )
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
end
