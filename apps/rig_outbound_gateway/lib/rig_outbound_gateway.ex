defmodule RigOutboundGateway do
  @moduledoc """
  Handles message delivery.
  """
  use Rig.Config, [:message_user_field]
  require Logger

  alias Phoenix.Channel.Server, as: PhoenixChannelServer

  @pubsub_server RigMesh.PubSub

  @type channel_name_t :: (String.t() -> String.t())
  @type broadcast_t :: (pid | atom, String.t(), String.t(), map -> any)
  @spec send(map, channel_name_t, broadcast_t) :: :ok | {:error, any}
  def send(
        payload,
        channel_name \\ &RigInboundGatewayWeb.Presence.Channel.user_channel_name/1,
        broadcast \\ &PhoenixChannelServer.broadcast/4
      ) do
    user_id = Map.fetch!(payload, config().message_user_field)
    topic = channel_name.(user_id)
    event = "message"
    broadcast.(@pubsub_server, topic, event, payload)
    Logger.debug(fn -> "message forwarded to #{user_id}: #{inspect payload}" end)
    :ok
  rescue
    err ->
      Logger.warn("#{inspect(err)} while parsing outbound message '#{inspect payload}'")
      {:error, err}
  end
end
