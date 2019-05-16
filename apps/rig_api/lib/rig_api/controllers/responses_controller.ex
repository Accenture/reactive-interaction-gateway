defmodule RigApi.ResponsesController do
  require Logger

  use RigApi, :controller
  use PhoenixSwagger

  alias Rig.Connection.Codec

  action_fallback(RigApi.FallbackController)

  swagger_path :create do
    post("/v1/responses")
    summary("Submit a message, to be sent to correlated reverse proxy request.")
    description("Allows you to submit a message to RIG using a simple, \
    synchronous call. Message will be sent to correlated reverse proxy request.")

    parameters do
      messageBody(
        :body,
        Schema.ref(:Response),
        "Response",
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
    with {:ok, rig_metadata} <- Map.fetch(message, "rig"),
         {:ok, correlation_id} <- Map.fetch(rig_metadata, "correlation"),
         {:ok, deserialized_pid} <- Codec.deserialize(correlation_id),
         {:ok, encoded_body} <- Jason.encode(message) do
      Logger.debug(fn ->
        "HTTP response via internal HTTP to #{inspect(deserialized_pid)}: #{inspect(message)}"
      end)

      send(deserialized_pid, {:response_received, encoded_body})
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
          title("Response object")
          description("A Response object that will be sent to correlated reverse proxy request.")

          properties do
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
