defmodule Gateway.ChannelsController do
  use Gateway.Web, :controller
  alias Gateway.PresenceChannel

  def list_channels(conn, _params) do
    channels =
      PresenceChannel.channels_list
      |> Map.keys

    json(conn, channels)
  end
  
  def list_channel_connections(conn, params) do
    %{"id" => id} = params

    connections =
      PresenceChannel.channels_list
      |> Map.get(id)

    json(conn, connections)
  end
end
