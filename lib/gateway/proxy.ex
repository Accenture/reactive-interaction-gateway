defmodule Gateway.Proxy do
  @moduledoc """
  Enables blacklisting of JWTs by their jti claim.

  The entries representing the banned claims feature an expiration timestamp,
  which prevents the blacklist from growing indefinitely.

  In a distributed setting, the node that does the blacklisting spreads the
  information via Phoenix' PubSub Server as Phoenix Presence information. The
  other nodes react by tracking the same record themselves, which means that
  for one record and n nodes there are n items in the Presence list. The
  following properties are a result of this:

  - Blacklisting can occur on/by any node.
  - The blacklist is eventually consistent over all nodes.
  - Any node can go down and come up at any time without affecting the
    blacklist, except if all nodes go down at the same time (in that case
    there is nothing to synchronize from -- the list is not stored on disk).

  """
  require Logger

  @typep state_t :: map

  @default_tracker_mod Gateway.ApiProxy.Tracker
  @config_file Application.fetch_env!(:gateway, :proxy_config_file)

  def start_link(tracker_mod \\ nil, opts \\ []) do
    tracker_mod = if tracker_mod, do: tracker_mod, else: @default_tracker_mod
    Logger.debug("API MANAGEMENT with tracker #{inspect tracker_mod}")
    GenServer.start_link(
      __MODULE__,
      _state = %{tracker_mod: tracker_mod},
      Keyword.merge([name: __MODULE__], opts))
  end

  def fill_presence() do
    Logger.info("Initializing presence with APIs")
    read_init_apis
    |> Enum.each(fn(api) ->
      api_id = Map.get(api, "id")
      GenServer.cast(Gateway.Proxy, {:add, api_id, api, nil})
    end)
  end

  def list_apis() do
    GenServer.call(Gateway.Proxy, {:list_api})
  end

  # callbacks
  
  @spec init(state_t) :: {:ok, state_t}
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add, api_id, api_map, listener}, state) do
    state.tracker_mod.track(api_id, api_map)
    IO.puts "----------STATE UPDATED-------"
    {:noreply, state}
  end

  def handle_call({:list_api}, _from, state) do
    list_of_apis = state.tracker_mod.list
    {:reply, list_of_apis, state}
  end

  # private functions

  defp read_init_apis do
    :gateway
    |> :code.priv_dir
    |> Path.join(@config_file)
    |> File.read!
    |> Poison.decode!
  end
end
