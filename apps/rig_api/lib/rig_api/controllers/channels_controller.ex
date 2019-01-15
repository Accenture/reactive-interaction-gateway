defmodule RigApi.ChannelsController do
  @moduledoc """
  HTTP-accessible API for client connections.

  """
  use RigApi, :controller
  require Logger
  alias RigAuth.Blacklist
  alias RigAuth.Jwt
  alias RigInboundGatewayWeb.Endpoint

  def list_channels(conn, _params) do
    Logger.warn("list_channels called but no longer implemented!")
    json(conn, [])
  end

  def list_channel_sessions(conn, %{"user" => _id}) do
    Logger.warn("list_channel_sessions called but no longer implemented!")
    json(conn, [])
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
