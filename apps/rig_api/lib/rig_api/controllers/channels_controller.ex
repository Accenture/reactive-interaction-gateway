defmodule RigApi.ChannelsController do
  @moduledoc """
  HTTP-accessible API for client connections.

  """
  use RigApi, :controller
  use Rig.Config, [:session_role]
  require Logger
  alias RigInboundGatewayWeb.Presence.Channel
  alias RigInboundGatewayWeb.Endpoint
  alias RigAuth.Blacklist
  alias RigAuth.Jwt

  def list_channels(conn, _params) do
    conf = config()
    channels =
      "role:#{conf.session_role}"
      |> Channel.channels_list
      |> Map.keys

    json(conn, channels)
  end

  def list_channel_sessions(conn, %{"user" => id}) do
    sessions =
      "user:#{id}"
      |> Channel.channels_list
      |> Enum.map(fn(user) -> elem(user, 1).metas end)
      |> List.flatten

    json(conn, sessions)
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
      Logger.warn("No token (expiration) found, using default blacklist expiration timeout (#{inspect e}).")
      nil
  end

  defp jwt_expiry_from_tokens([]), do: nil
  defp jwt_expiry_from_tokens([token]) do
    {:ok, %{"exp" => expiry}} = Jwt.Utils.decode(token)
    expiry
    |> Integer.to_string  # Comes as int, convert to string
    |> Timex.parse!("{s-epoch}")  # Parse as UTC epoch
  end
end
