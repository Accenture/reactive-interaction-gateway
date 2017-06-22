defmodule Gateway.ChannelsController do
  use Gateway.Web, :controller
  alias Gateway.PresenceChannel
  alias Gateway.Endpoint
  alias Gateway.Blacklist

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

  def disconnect_channel_connection(conn, %{"jti" => jti}) do
    Blacklist.add_jti(Blacklist, jti)
    Endpoint.broadcast(jti, "disconnect", %{})

    conn
    |> put_status(204)
    |> json(%{})
  end
end
