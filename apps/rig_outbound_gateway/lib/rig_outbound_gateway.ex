defmodule RigOutboundGateway do
  @moduledoc """
  Handles message delivery.
  """
  use Rig.Config, [:message_user_field]
  require Logger

  alias Rig.CloudEvent
  alias Rig.EventFilter

  alias Phoenix.Channel.Server, as: PhoenixChannelServer

  @pubsub_server Rig.PubSub

  def handle_raw(raw, parse, send, ack) do
    case parse.(raw) do
      {:ok, payload} -> handle_map(payload, send, ack)
      err -> err
    end
  end

  def handle_map(payload, send, ack) do
    case send.(payload) do
      :ok ->
        ack.()
        :ok

      err ->
        err
    end
  end

  @type channel_name_t :: (String.t() -> String.t())
  @type broadcast_t :: (pid | atom, String.t(), String.t(), map -> any)
  @spec send(map, channel_name_t, broadcast_t) :: :ok | {:error, any}
  def send(
        payload,
        channel_name \\ &RigInboundGatewayWeb.Presence.Channel.user_channel_name/1,
        broadcast \\ &PhoenixChannelServer.broadcast/4
      ) do
    user_id = Map.fetch!(payload, config().message_user_field)
    channel_topic = channel_name.(user_id)
    event = "message"
    broadcast.(@pubsub_server, channel_topic, event, payload)

    # TODO this is to replace the phoenix-pubsub broadcast:
    maybe_publish_to_event_hub(payload)

    Logger.debug(fn ->
      meta =
        [user_id: user_id, channel: channel_topic, body_raw: inspect(payload)]
        |> RigOutboundGateway.Logger.trunc_body()

      {"Forwarded outbound message", meta}
    end)

    :ok
  rescue
    err ->
      {:error, err}
  end

  defp maybe_publish_to_event_hub(payload) do
    case CloudEvent.new(payload) do
      {:ok, cloud_event} ->
        Logger.debug(fn -> "[outbound] Forwarding: #{cloud_event}" end)
        EventFilter.forward_event(cloud_event)

      {:error, :parse_error} ->
        Logger.debug(fn -> "Not a CloudEvent: #{inspect(payload)}" end)
    end
  end
end
