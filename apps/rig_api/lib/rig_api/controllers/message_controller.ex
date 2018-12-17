defmodule RigApi.MessageController do
  require Logger

  use RigApi, :controller
  use PhoenixSwagger

  alias CloudEvent

  action_fallback(RigApi.FallbackController)

  @event_filter Application.get_env(:rig, :event_filter)


  # Swagger documentation for endpoint POST /v1/messages
  swagger_path :create do
    post("/v1/messages")
    summary("Message Acception")
    description("Accepts message to be sent to front-ends.")

    parameters do
      messageBody(
        :body,
        Schema.ref(:MessageCloudEvent),
        "The message to be provided to frontends in Cloud Event format",
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
    with {:ok, cloud_event} <- CloudEvent.new(message) do
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
      MessageCloudEvent:
        swagger_schema do
          title("Message Cloud Event")
          description("The message to be provide to frontends in Cloud Event format")
          properties do  
            cloudEventsVersion(:string, "Cloud Events Version", required: true, example: "0.1")
            eventID(:string, "unique ID for an event", required: true, example: "first-event")
            eventTime(:string, "Event Time", required: true, example: "2018-08-21T09:11:27.614970+00:00")
            eventType(:string, "the event type in reverse-DNS notation", required: true, example: "greeting")
            source(:string, "describes the event producer.", required: true, example: "tutorial")
            # extensions(:string, "Cloud events extensions.", required: false)
            # schemaURL(:string, "Schema URL", required: false)
            # contentType(:string, "Content Type", required: false)
            # data(:string, "Data", required: false)
          end
        end
    }
  end
end
