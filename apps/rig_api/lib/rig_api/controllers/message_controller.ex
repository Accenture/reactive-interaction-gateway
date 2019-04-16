defmodule RigApi.MessageController do
  require Logger

  use RigApi, :controller
  use PhoenixSwagger

  alias RigCloudEvents.CloudEvent

  action_fallback(RigApi.FallbackController)

  @event_filter Application.get_env(:rig, :event_filter)

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

  Note that `message` is _always_ a map. For example:

  - Given '"foo"', the `:json` parser will pass '{"_json": "foo"}'.
  - Given 'foo', the `:urlencoded` parser will pass '{"foo": nil}'.
  """
  def create(conn, message) do
    with {:ok, cloud_event} <- CloudEvent.parse(message) do
      @event_filter.forward_event(cloud_event)

      send_resp(conn, :accepted, "message queued for transport")
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> text("Failed to parse request body: #{inspect(reason)}")
    end
  end

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
