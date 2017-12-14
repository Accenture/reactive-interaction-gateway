defmodule RigInboundGateway.Blacklist.PresenceHandler do
  @moduledoc """
  Handles Phoenix Presence events.

  Implemented as a Phoenix.Tracker, this module tracks all events it receives
  from the given Phoenix PubSub server. Only join events that refer to the
  `@blacklist_topic` are considered for inclusion into the blacklist, and
  leave events are ignored (i.e., forwarded only).

  The blacklist server is started from, and linked against, this server.

  """
  require Logger
  @behaviour Phoenix.Tracker

  alias RigInboundGateway.Blacklist

  @blacklist_topic "blacklist"

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    GenServer.start_link(
      Phoenix.Tracker,
      [__MODULE__, opts, opts],
      name: __MODULE__)
  end

  # callbacks

  @impl Phoenix.Tracker
  def init(opts) do
    {:ok, blacklist} = Blacklist.start_link()
    pubsub = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{
      pubsub_server: pubsub,
      node_name: Phoenix.PubSub.node_name(pubsub),
      blacklist: blacklist,
      }
    }
  end

  @doc """
  Forwards joins on the "blacklist" topic to the Blacklist server.

  Leave events are ignored, as the Blacklist server doesn't handle them. This is
  because we cannot distinguish between an expiry event and an offline node;
  therefore, each node expires the entries by itself.
  """
  @impl Phoenix.Tracker
  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        if topic == @blacklist_topic do
          [jti, expiry] = [key, Map.get(meta, :expiry)]
          state.blacklist |> Blacklist.add_jti(jti, expiry)
        end
        msg = {:join, key, meta}
        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end
      for {key, meta} <- leaves do
        msg = {:leave, key, meta}
        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end
    end
    {:ok, state}
  end
end
