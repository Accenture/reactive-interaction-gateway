defmodule RigApi.V2.Responses do
  @moduledoc "Controller for submitting (backend) responses to asynchronous (frontend) requests."
  require Logger

  use RigApi, :controller
  use PhoenixSwagger

  alias Rig.Connection.Codec
  alias RigCloudEvents.CloudEvent

  @prefix "/v2"

  action_fallback(RigApi.Fallback)

  swagger_path :create do
    post(@prefix <> "/responses")
    summary("Submit a message, to be sent to correlated reverse proxy request.")
    description("Allows you to submit a message to RIG using a simple, \
    synchronous call. Message will be sent to correlated reverse proxy request.")

    parameters do
      messageBody(
        :body,
        Schema.ref(:CloudEvent),
        "CloudEvent",
        required: true
      )
    end

    response(202, "Accepted - message sent to correlated reverse proxy request")
    response(400, "Bad Request: Failed to parse request body :parse-error")
  end

  @doc """
  Accepts message to be sent to correlated HTTP process.
  Note that body has to contain following field `"rig": { "correlation": "_id_" }`.
  """
  def create(conn, message) do
    with {:ok, cloud_event} <- CloudEvent.parse(message),
         {:ok, rig_metadata} <- Map.fetch(message, "rig"),
         {:ok, correlation_id} <- Map.fetch(rig_metadata, "correlation"),
         {:ok, deserialized_pid} <- Codec.deserialize(correlation_id) do
      Logger.debug(fn ->
        "HTTP response via internal HTTP to #{inspect(deserialized_pid)}: #{inspect(message)}"
      end)

      send(deserialized_pid, {:response_received, cloud_event.json})
      send_resp(conn, :accepted, "message sent to correlated reverse proxy request")
    else
      err ->
        Logger.warn(fn -> "Parse error #{inspect(err)} for #{inspect(message)}" end)

        conn
        |> put_status(:bad_request)
        |> text("Failed to parse request body: #{inspect(err)}")
    end
  end

  def swagger_definitions do
    %{
      Response:
        swagger_schema do
          title("CloudEvent")
          description("The CloudEvent that will be sent to correlated reverse proxy request.")

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

            rig(
              Schema.new do
                properties do
                  correlation(:string, "Correlation ID",
                    required: true,
                    example: "g2dkAA1ub25vZGVAbm9ob3N0AAADxwAAAAAA"
                  )
                end
              end
            )
          end
        end
    }
  end
end
