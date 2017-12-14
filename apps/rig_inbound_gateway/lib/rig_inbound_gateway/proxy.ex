defmodule RigInboundGateway.Proxy do
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
  use Rig.Config, []  # config file is not required
  require Logger

  @type endpoint :: %{
    optional(:not_secured) => boolean,
    id: String.t,
    path: String.t,
    method: String.t,
}
  @type api_definition :: %{
    optional(:auth_type) => String.t,
    optional(:versioned) => boolean,
    optional(:active) => boolean,
    optional(:node_name) => atom,
    optional(:ref_number) => integer,
    optional(:timestamp) => DateTime,
    id: String.t,
    name: String.t,
    auth: %{
      optional(:use_header) => boolean,
      optional(:header_name) => String.t,
      optional(:use_query) => boolean,
      optional(:query_name) => String.t,
    },
    version_data: %{
      optional(String.t) => %{
        endpoints: [endpoint]
      }
    },
    proxy: %{
      optional(:use_env) => boolean,
      target_url: String.t,
      port: integer,
    },
  }

  @typep state_t :: map
  @typep server_t :: pid | atom

  defmodule ProxyBehaviour do
    @moduledoc false
    @callback list_apis(server :: Proxy.server_t) :: [Proxy.api_definition, ...]
    @callback get_api(id :: Proxy.server_t, id :: String.t) :: Proxy.api_definition
    @callback add_api(id :: Proxy.server_t, id :: String.t, api :: Proxy.api_definition) :: any
    @callback replace_api(id :: Proxy.server_t, id :: String.t, prev_api :: Proxy.api_definition,
      next_api :: Proxy.api_definition) :: any
    @callback update_api(id :: Proxy.server_t, id :: String.t, api :: Proxy.api_definition) :: any
    @callback deactivate_api(id :: Proxy.server_t, id :: String.t) :: atom
  end

  @behaviour ProxyBehaviour

  @default_tracker_mod RigInboundGateway.ApiProxy.Tracker

  def start_link(tracker_mod \\ nil, opts \\ []) do
    tracker_mod = if tracker_mod, do: tracker_mod, else: @default_tracker_mod
    Logger.debug(fn -> "API proxy with tracker #{inspect tracker_mod}" end)
    GenServer.start_link(
      __MODULE__,
      _state = %{tracker_mod: tracker_mod},
      Keyword.merge([name: __MODULE__], opts))
  end

  @spec init_presence(state_t) :: :ok
  def init_presence(state) do
    Logger.info("Initial loading of API definitions to presence")
    conf = config()

    conf.config_file
    |> read_init_apis
    |> Enum.each(fn(api) ->
      api_with_default_values = set_default_api_values(api)
      state.tracker_mod.track(api["id"], api_with_default_values)
    end)
  end

  @impl ProxyBehaviour
  def list_apis(server) do
    GenServer.call(server, {:list_apis})
  end

  @impl ProxyBehaviour
  def get_api(server, id) do
    GenServer.call(server, {:get_api, id})
  end

  @impl ProxyBehaviour
  def add_api(server, id, api) do
    GenServer.call(server, {:add_api, id, api})
  end

  @impl ProxyBehaviour
  def replace_api(server, id, prev_api, next_api) do
    GenServer.call(server, {:replace_api, id, prev_api, next_api})
  end

  @impl ProxyBehaviour
  def update_api(server, id, api) do
    GenServer.call(server, {:update_api, id, api})
  end

  @impl ProxyBehaviour
  def deactivate_api(server, id) do
    GenServer.call(server, {:deactivate_api, id})
  end

  @spec handle_join_api(server_t, String.t, api_definition) :: server_t
  def handle_join_api(server, id, api) do
    GenServer.cast(server, {:handle_join_api, id, api})
  end

  # callbacks

  @spec init(state_t) :: {:ok, state_t}
  def init(state) do
    send(self(), :init_apis)
    {:ok, state}
  end

  @spec handle_info(:init_apis, state_t) :: {:noreply, state_t}
  def handle_info(:init_apis, state) do
    init_presence(state)
    {:noreply, state}
  end

  @spec handle_call({:add_api, String.t, api_definition}, any, state_t) :: {:reply, any, state_t}
  def handle_call({:add_api, id, api}, _from, state) do
    Logger.info("Handling add of new API definition with id=#{id}")

    api_with_default_values = set_default_api_values(api)

    response = state.tracker_mod.track(id, api_with_default_values)
    {:reply, response, state}
  end

  @spec handle_call({:replace_api, String.t, api_definition, api_definition}, any, state_t)
    :: {:reply, any, state_t}
  def handle_call({:replace_api, id, prev_api, next_api}, _from, state) do
    Logger.info("Handling replace of deactivated API definition with id=#{id} with new API")

    api_with_default_values =
      set_default_api_values(next_api)
      |> Map.put("ref_number", prev_api["ref_number"] + 1)

    response = state.tracker_mod.update(id, api_with_default_values)
    {:reply, response, state}
  end

  @spec handle_call({:update_api, String.t, api_definition}, any, state_t) :: {:reply, any, state_t}
  def handle_call({:update_api, id, api}, _from, state) do
    Logger.info("Handling update of API definition with id=#{id}")

    meta_info = %{"ref_number" => api["ref_number"] + 1, "timestamp" => Timex.now}
    api_with_meta_info = add_meta_info(api, meta_info)

    response = state.tracker_mod.update(id, api_with_meta_info)
    {:reply, response, state}
  end

  @spec handle_call({:deactivate_api, String.t, api_definition}, any, state_t)
    :: {:reply, atom, state_t}
  def handle_call({:deactivate_api, id}, _from, state) do
    node_name = get_node_name()
    Logger.info("Handling deactivate of API definition with id=#{id} in presence")

    {_id, current_api} = state.tracker_mod.find_by_node(id, node_name)
    api =
      current_api
      |> Map.update("ref_number", 0, &(&1 + 1))
      |> Map.put("active", false)
      |> Map.put("timestamp", Timex.now)

    response = state.tracker_mod.update(id, api)
    {:reply, response, state}
  end

  @spec handle_call({:list_apis}, any, state_t) :: {:reply, [api_definition, ...], state_t}
  def handle_call({:list_apis}, _from, state) do
    list_of_apis = get_node_name() |> state.tracker_mod.list_by_node
    {:reply, list_of_apis, state}
  end

  @spec handle_call({:get_api}, any, state_t) :: {:reply, api_definition, state_t}
  def handle_call({:get_api, id}, _from, state) do
    node_name = get_node_name()
    api = state.tracker_mod.find_by_node(id, node_name)

    {:reply, api, state}
  end

  # Handle incoming JOIN events with new data from Presence
  @spec handle_cast({:handle_join_api, String.t, api_definition}, state_t) :: {:noreply, state_t}
  def handle_cast({:handle_join_api, id, api}, state) do
    node_name = get_node_name()
    Logger.info("Handling JOIN differential for API definition with id=#{id} for node=#{node_name}")

    prev_api = state.tracker_mod.find_by_node(id, node_name)

    case compare_api(id, prev_api, api, state) do
      {:error, :exit} ->
        Logger.debug(fn -> "There is already most recent API definition with id=#{id} in presence" end)
      {:ok, :track} ->
        Logger.debug(fn -> "API definition with id=#{id} doesn't exist yet, starting to track" end)
        api_with_default_values = set_default_api_values(api)

        state.tracker_mod.track(id, api_with_default_values)
      {:ok, :update_no_ref} ->
        Logger.debug(fn -> "API definition with id=#{id} is adopting new version with no ref_number update" end)
        state.tracker_mod.update(id, add_meta_info(api))
      {:ok, :update_with_ref} ->
        Logger.debug(fn -> "API definition with id=#{id} is adopting new version with ref_number update" end)

        prev_api_data = elem(prev_api, 1)
        meta_info = %{"ref_number" => prev_api_data["ref_number"] + 1}
        api_with_meta_info = add_meta_info(api, meta_info)

        state.tracker_mod.update(id, api_with_meta_info)
    end

    {:noreply, state}
  end

  # private functions

  # Compare current API and new API based by ID
  # Comparison is done by several steps:
  #   - Reference number
  #   - Data equality (without internal information like phx_ref, node_name, timestamp, etc.)
  #   - Data equality across nodes in cluster (without internal information ...)
  #   - Timestamp
  @spec compare_api(String.t, nil, api_definition, state_t) :: {:ok, :track}
  defp compare_api(_id, nil, _next_api, _state), do: {:ok, :track}
  @spec compare_api(String.t, {String.t, api_definition}, api_definition, state_t) :: {atom, atom}
  defp compare_api(id, {id, prev_api}, next_api, state) do
    cond do
      # Evaluate only active APIs with equal reference number
      #   -> prevent deactivated API overriding on node start-up
      # Freshly deactivated APIs have incremented reference number => not equal
      next_api["ref_number"] == prev_api["ref_number"] && prev_api["active"] == true ->
        eval_data_change(id, prev_api, next_api, state)
      next_api["ref_number"] > prev_api["ref_number"] -> {:ok, :update_with_ref}
      true -> {:error, :exit}
    end
  end

  # Evaluate if current API and new API are the same or not => data wise
  @spec eval_data_change(String.t, api_definition, api_definition, state_t) :: {atom, atom}
  defp eval_data_change(id, prev_api, next_api, state) do
    if data_equal?(prev_api, next_api) do
      {:error, :exit}
    else
      eval_all_nodes_data(id, prev_api, next_api, state)
    end
  end

  # Evaluate how many nodes have data from new API
  # If exactly half of the nodes are different => compare timestamps
  @spec eval_all_nodes_data(String.t, api_definition, api_definition, state_t) :: {atom, atom}
  defp eval_all_nodes_data(id, prev_api, next_api, state) do
    all_api_instances = state.tracker_mod.find_all(id)
    n_api_instances_halved = length(all_api_instances) / 2

    matching_api_instances = all_api_instances |> Enum.filter(fn({_key, meta}) ->
      meta |> data_equal?(next_api)
    end)
    n_matching_api_instances = length(matching_api_instances)

    cond do
      n_matching_api_instances < n_api_instances_halved -> {:error, :exit}
      n_matching_api_instances > n_api_instances_halved -> {:ok, :update_no_ref}
      true ->
        next_api["timestamp"]
        |> Timex.after?(prev_api["timestamp"])
        |> eval_time
    end
  end

  # Checks if current API and new API are equal => data wise
  # Strips internal information such as timestamp, phx_ref, node_name, ...
  @spec data_equal?(api_definition, api_definition) :: boolean
  defp data_equal?(prev_api, next_api) do
    next_api_without_meta = next_api |> remove_meta_info

    prev_api
    |> remove_meta_info
    |> Map.equal?(next_api_without_meta)
  end

  @spec eval_time(false) :: {:error, :exit}
  defp eval_time(false) do
    {:error, :exit}
  end
  @spec eval_time(true) :: {:ok, :update_no_ref}
  defp eval_time(true) do
    {:ok, :update_no_ref}
  end

  @spec get_node_name() :: atom
  defp get_node_name, do: Phoenix.PubSub.node_name(RigMesh.PubSub)

  # Enhance API definition with internal information
  @spec add_meta_info(api_definition, map) :: api_definition
  defp add_meta_info(api, meta_info \\ %{}) do
    api
    |> Map.merge(meta_info)
    |> Map.put("node_name", get_node_name())
  end

  # Remove internal information from API definition => to have just raw data
  @spec remove_meta_info(api_definition) :: api_definition
  defp remove_meta_info(api) do
    api
    |> Map.delete(:phx_ref)
    |> Map.delete(:phx_ref_prev)
    |> Map.delete("node_name")
    |> Map.delete("timestamp")
  end

  @spec read_init_apis(String.t | nil) :: [api_definition]
  defp read_init_apis(nil), do: []
  defp read_init_apis(config_file) do
    :rig_inbound_gateway
    |> :code.priv_dir
    |> Path.join(config_file)
    |> File.read!
    |> Poison.decode!
  end

  @spec set_default_api_values(api_definition) :: api_definition
  defp set_default_api_values(api) do
    default_api_values = %{
      "active" => true,
      "auth_type" => "none",
      "proxy" => %{
        "use_env" => false
      },
      "ref_number" => 0,
      "timestamp" => Timex.now,
      "versioned" => false
    }

    api_with_default =
      default_api_values
      |> Map.merge(api)
      |> Map.put("node_name", get_node_name()) # Make sure API has always origin node
    auth_default_values = get_default_auth_values(api_with_default["auth_type"])

    api_with_default |> Map.put("auth", auth_default_values)
  end

  @spec get_default_auth_values(String.t) :: map
  defp get_default_auth_values(type) do
    query_default_values = %{"use_query" => false, "query_name" => ""}

    header_default_values =
      case type do
        "jwt" -> %{"use_header" => true, "header_name" => "Authorization"}
        _ -> %{"use_header" => false, "header_name" => ""}
      end

    query_default_values |> Map.merge(header_default_values)
  end
end
