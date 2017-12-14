defmodule RigInboundGateway.ApiProxy.PresenceHandler do
  @moduledoc """
  Handles Phoenix Presence events.

  Implemented as a Phoenix.Tracker, this module tracks all events it receives
  from the given Phoenix PubSub server. Only join events that refer
  to the `@proxy` topic are considered for inclusion into the PROXY.

  The PROXY server is started from, and linked against, this server.

  """
  require Logger
  @behaviour Phoenix.Tracker

  alias RigInboundGateway.Proxy

  @topic "proxy"

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
    {:ok, proxy} = Proxy.start_link()
    pubsub = Keyword.fetch!(opts, :pubsub_server)

    {:ok, %{
      pubsub_server: pubsub,
      node_name: Phoenix.PubSub.node_name(pubsub),
      proxy: proxy,
      }
    }
  end

  @doc """
  Forwards joins on the "proxy" topic to the Proxy server.

  Leaves are not handled since we want to keep track of removed APIs and potentially
  renew them.
  """
  @impl Phoenix.Tracker
  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        if topic == @topic do
          state.proxy |> Proxy.handle_join_api(key, meta)
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
