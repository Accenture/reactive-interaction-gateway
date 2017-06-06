defmodule Gateway.ChannelsController do
  use Gateway.Web, :controller
  alias Gateway.PresenceChannel
  alias Gateway.Endpoint

  def list_channels(conn, _params) do
    channels =
      "role:customer"
      |> PresenceChannel.channels_list
      |> Map.keys

    json(conn, channels)
  end

  def list_channel_connections(conn, params) do
    %{"id" => id} = params

    connections =
      "user:#{id}"
      |> PresenceChannel.channels_list
      |> Enum.map(fn(user) -> elem(user, 1).metas end)
      |> List.flatten

    json(conn, connections)
  end

  def disconnect_channel_connection(conn, params) do
    %{"jti" => jti} = params

    "role:customer"
    |> PresenceChannel.channels_list
    |> Enum.find(fn(user) ->
      elem(user, 1).metas
      |> Enum.find(fn(user_info) -> Map.get(user_info, "jti") == jti end)
    end)
    |> find_username
    |> send_response(jti, conn)
  end

  defp find_username(nil), do: nil
  defp find_username(user_info) do
    user_info
    |> elem(1)
    |> Map.get(:metas)
    |> List.first
    |> Map.get("username")
  end

  defp send_response(nil, _jti, conn) do
    conn
    |> put_status(404)
    |> json(%{})
  end

  defp send_response(username, jti, conn) do
    Endpoint.broadcast(
      "user:#{username}",
      "kill",
      %{msg: "You have been forcefully logged out."}
    )
    Endpoint.broadcast(jti, "disconnect", %{})

    conn
    |> put_status(204)
    |> json(%{})
  end
end
