defmodule Gateway.ApiProxy.PresenceHandler do
  @moduledoc """
  Handles Phoenix Presence events.

  Implemented as a Phoenix.Tracker, this module tracks all events it receives
  from the given Phoenix PubSub server. Only join/leave/update events that refer to the
  `@proxy` topic are considered for inclusion into the PROXY APIs.

  The API PROXY server is started from, and linked against, this server.

  """
  require Logger
  @behaviour Phoenix.Tracker

  alias Gateway.ProxyTest

  @topic "proxy"

  def start_link(opts) do
    IO.inspect opts
    opts = Keyword.merge([name: __MODULE__], opts)
    IO.puts "---MERGED---"
    IO.inspect opts
    GenServer.start_link(
      Phoenix.Tracker,
      [__MODULE__, opts, opts],
      name: __MODULE__)
  end

  # callbacks

  @impl Phoenix.Tracker
  def init(opts) do
    {:ok, proxy_test} = ProxyTest.start_link()
    pubsub = Keyword.fetch!(opts, :pubsub_server)
    IO.puts "starting with filling"
    ProxyTest.fill_presence
    IO.puts "init pubsub"
    IO.inspect proxy_test
    {:ok, %{
      pubsub_server: pubsub,
      node_name: Phoenix.PubSub.node_name(pubsub),
      proxy_test: proxy_test,
      }
    }
  end

  @doc """
  Forwards joins on the "blacklist" topic to the Blacklist server.

  """
  @impl Phoenix.Tracker
  def handle_diff(diff, state) do
    IO.puts "handle_diff"
    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        IO.inspect key
        IO.inspect meta
        # TODO: GENSERVER SYNC ??
        # if topic == @topic do
        #   [jti, expiry] = [key, Map.get(meta, :expiry)]
        #   state.blacklist |> Blacklist.add_jti(jti, expiry)
        # end
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
