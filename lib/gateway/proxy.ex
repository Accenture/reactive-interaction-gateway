defmodule Gateway.Proxy do
  @moduledoc """
  Enables persisting and CRUD operations for Proxy's API definitions in presence.

  In a distributed setting, the node that does the persisting of API definitions
  spreads the information via Phoenix' PubSub Server as Phoenix Presence information.
  The other nodes react by tracking the same record themselves, which means that
  for one record and n nodes there are n items in the Presence list. The
  following properties are a result of this:

  - API definitions managing can occur on/by any node.
  - API definitions are eventually consistent over all nodes.
  - Any node can go down and come up at any time without affecting the
    API definitions, except if all nodes go down at the same time (in that case
    there is nothing to synchronize from -- changes are not stored on disk).

  """
  require Logger

  @typep state_t :: map

  @default_tracker_mod Gateway.ApiProxy.Tracker
  @config_file Application.fetch_env!(:gateway, :proxy_config_file)

  def start_link(tracker_mod \\ nil, opts \\ []) do
    tracker_mod = if tracker_mod, do: tracker_mod, else: @default_tracker_mod
    Logger.debug("API proxy with tracker #{inspect tracker_mod}")
    GenServer.start_link(
      __MODULE__,
      _state = %{tracker_mod: tracker_mod},
      Keyword.merge([name: __MODULE__], opts))
  end

  def init_presence do
    Logger.info("Initial loading of API definitions to presence")
    read_init_apis()
    |> Enum.each(fn(api) -> add_api(Gateway.Proxy, api["id"], api) end)
  end

  def list_apis do
    GenServer.call(Gateway.Proxy, {:list_api})
  end

  @spec add_api(pid | atom, String.t, map) :: pid
  def add_api(server, id, api) do
    GenServer.cast(server, {:add, id, api})
    server  # allow for chaining calls
  end

  # callbacks

  @spec init(state_t) :: {:ok, state_t}
  def init(state) do
    send(self(), :init_apis)
    {:ok, state}
  end

  @spec handle_info(:init_apis, state_t) :: {:noreply, state_t}
  def handle_info(:init_apis, state) do
    init_presence()
    {:noreply, state}
  end

  @spec handle_cast({:add, String.t, map}, state_t) :: {:noreply, state_t}
  def handle_cast({:add, api_id, api_map}, state) do
    Logger.info("Adding new API definition with id=#{api_id} to presence")
    state.tracker_mod.track(api_id, api_map)
    {:noreply, state}
  end

  @spec handle_call({:list_api}, any, state_t) :: {:reply, state_t}
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
