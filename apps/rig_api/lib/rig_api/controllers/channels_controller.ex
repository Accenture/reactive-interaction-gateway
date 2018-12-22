defmodule RigApi.ChannelsController do
  @moduledoc """
  HTTP-accessible API for client connections.

  """
  use RigApi, :controller
  use Rig.Config, [:session_role]
  use PhoenixSwagger
  require Logger
  alias RigAuth.Blacklist
  alias RigAuth.Jwt
  alias RigInboundGatewayWeb.Endpoint

  def swagger_definitions do
    %{
      User:
        swagger_schema do
          title("tbd")
          description("tbd")

          properties do
            userId(:string, "tbd", required: true)
          end

          example(%{
            userId: "SomeUserId"
          })
        end,
      Users:
        swagger_schema do
          title("tbd")
          description("tbd")
          type(:array)
          items(Schema.ref(:User))
        end
    }
  end

  # Swagger documentation for endpoint GET /v1/users
  swagger_path :list_channels do
    get("/v1/users")
    summary("tbd")
    description("tbd")

    response(200, "Ok", Schema.ref(:Users))
  end

  def list_channels(conn, _params) do
    Logger.warn("list_channels called but no longer implemented!")
    json(conn, [])
  end

  # Swagger documentation for endpoint GET /v1/users/:user/sessions
  swagger_path :list_channel_sessions do
    get("/v1/users/{user}/sessions")
    summary("tbd")
    description("tbd")

    parameters do
      user(:path, :string, "tbd", required: true)
    end

    response(200, "Ok")
  end

  def list_channel_sessions(conn, %{"user" => _id}) do
    Logger.warn("list_channel_sessions called but no longer implemented!")
    json(conn, [])
  end

  # Swagger documentation for endpoint DELETE /v1/tokens/:jti
  swagger_path :disconnect_channel_session do
    delete("/v1/tokens/{jti}")
    summary("tbd")
    description("tbd")

    parameters do
      jti(:path, :string, "tbd", required: true)
    end

    response(200, "Ok")
  end

  def disconnect_channel_session(conn, %{"jti" => jti}) do
    Blacklist.add_jti(Blacklist, jti, jwt_expiry(conn))
    Endpoint.broadcast(jti, "disconnect", %{})

    conn
    |> put_status(204)
    |> json(%{})
  end

  defp jwt_expiry(conn) do
    conn
    |> get_req_header("authorization")
    |> jwt_expiry_from_tokens
  rescue
    e ->
      Logger.warn(
        "No token (expiration) found, using default blacklist expiration timeout (#{inspect(e)})."
      )

      nil
  end

  defp jwt_expiry_from_tokens([]), do: nil

  defp jwt_expiry_from_tokens([token]) do
    {:ok, %{"exp" => expiry}} = Jwt.Utils.decode(token)

    expiry
    # Comes as int, convert to string
    |> Integer.to_string()
    # Parse as UTC epoch
    |> Timex.parse!("{s-epoch}")
  end
end
