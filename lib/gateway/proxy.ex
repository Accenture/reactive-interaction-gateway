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

  @type endpoint :: %{
    id: String.t,
    path: String.t,
    method: String.t,
    not_secured: boolean,
  }
  @type api_definition :: %{
    id: String.t,
    name: String.t,
    auth: String.t,
    auth_type: %{
      use_header: boolean,
      header_name: String.t,
      use_query: boolean,
      query_name: String.t,
    },
    versioned: boolean,
    version_data: %{
      optional(String.t) => %{
        endpoints: [endpoint]
      }
    },
    proxy: %{
      use_env: boolean,
      target_url: String.t,
      port: integer,
    },
  } # TODO fields: active, node_name, ref_number, timestamp

  @typep state_t :: map
  @typep server_t :: pid | atom

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

  @spec init_presence(state_t) :: TODO
  def init_presence(state) do
    Logger.info("Initial loading of API definitions to presence")
    read_init_apis()
    |> Enum.each(fn(api) ->
      meta_info = %{"ref_number" => 0, "timestamp" => Timex.now, "active" => true}
      api_with_meta_info = add_meta_info(api, meta_info)

      state.tracker_mod.track(api["id"], api_with_meta_info)
    end)
  end

  @spec list_apis(server_t) :: [api_definition, ...]
  def list_apis(server) do
    GenServer.call(server, {:list_api})
  end

  @spec get_api(server_t, String.t) :: api_definition
  def get_api(server, id) do
    GenServer.call(server, {:get_api, id})
  end

  @spec add_api(server_t, String.t, api_definition) :: any
  def add_api(server, id, api) do
    GenServer.call(server, {:add_api, id, api})
  end

  @spec update_api(server_t, String.t, api_definition) :: any
  def update_api(server, id, api) do
    GenServer.call(server, {:update_api, id, api})
  end

  @spec delete_api(server_t, String.t) :: atom
  def delete_api(server, id) do
    GenServer.call(server, {:deactivate_api, id})
  end

  @spec handle_join_api(server_t, String.t, api_definition) :: server_t
  def handle_join_api(server, id, api) do
    GenServer.cast(server, {:handle_join_api, id, api})
  end

  @spec handle_leave_api(server_t, String.t, api_definition) :: server_t
  def handle_leave_api(server, id, api) do
    GenServer.cast(server, {:handle_leave_api, id, api})
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

  # Handle incoming JOIN events with new data from Presence
  @spec handle_cast({:handle_join_api, String.t, api_definition}, state_t) :: {:noreply, state_t}
  def handle_cast({:handle_join_api, id, api}, state) do
    node_name = get_node_name()
    Logger.info("Handling JOIN differential for API definition with id=#{id} for node=#{node_name}")

    prev_api = state.tracker_mod.find_by_node(id, node_name)

    case compare_api(id, prev_api, api, state) do
      {:error, :exit} ->
        Logger.debug("There is already most recent API definition with id=#{id} in presence")
      {:ok, :track} ->
        Logger.debug("API definition with id=#{id} doesn't exist yet, starting tracking")
        meta_info = %{"ref_number" => 0, "timestamp" => Timex.now, "active" => true}
        api_with_meta_info = add_meta_info(api, meta_info)

        state.tracker_mod.track(id, api_with_meta_info)
      {:ok, :update_no_ref} ->
        Logger.debug("API definition with id=#{id} adopted new version with no ref_number update")
        state.tracker_mod.update(id, add_meta_info(api))
      {:ok, :update_with_ref} ->
        Logger.debug("API definition with id=#{id} adopted new version with ref_number update")

        prev_api_data = elem(prev_api, 1)
        meta_info = %{"ref_number" => prev_api_data["ref_number"] + 1}
        api_with_meta_info = add_meta_info(api, meta_info)

        state.tracker_mod.update(id, api_with_meta_info)
    end

    {:noreply, state}
  end

  # Handle incoming LEAVE events with old data from Presence
  # @spec handle_cast({:handle_leave_api, String.t, api_definition}, state_t) :: {:noreply, state_t}
  # def handle_cast({:handle_leave_api, id, api}, state) do
  #   node_name = get_node_name()
  #   Logger.info("Handling LEAVE differential for API definition with id=#{id} for node=#{node_name}")
  # 
  #   case check_node_origin(id, api, node_name, state) do
  #     {:error, :exit} ->
  #       Logger.debug("Skipped deletion of API definition with id=#{id} from presence")
  #     {:ok, :untrack} ->
  #       Logger.debug("Deleting API definition with id=#{id} from presence")
  #       state.tracker_mod.untrack(id)
  #   end
  # 
  #   {:noreply, state}
  # end

  @spec handle_call({:add_api, String.t, api_definition}, any, state_t) :: {:reply, any, state_t}
  def handle_call({:add_api, id, api}, _from, state) do
    Logger.info("Adding new API definition with id=#{id} to presence")

    meta_info = %{"ref_number" => 0, "timestamp" => Timex.now}
    api_with_meta_info =
      api
      |> Map.merge(meta_info)
      |> Map.put("active", true) # TODO default values
      |> Map.put_new("node_name", get_node_name())

    response = state.tracker_mod.track(id, api_with_meta_info)
    {:reply, response, state}
  end

  @spec handle_call({:update_api, String.t, api_definition}, any, state_t) :: {:reply, any, state_t}
  def handle_call({:update_api, id, api}, _from, state) do
    Logger.info("Updating API definition with id=#{id} in presence")

    meta_info = %{"ref_number" => api["ref_number"] + 1, "timestamp" => Timex.now}
    api_with_meta_info = add_meta_info(api, meta_info)

    response = state.tracker_mod.update(id, api_with_meta_info)
    {:reply, response, state}
  end

  @spec handle_call({:deactivate_api, String.t, api_definition}, any, state_t) :: {:reply, atom, state_t}
  def handle_call({:deactivate_api, id}, _from, state) do
    node_name = get_node_name()
    Logger.info("Deactivating API definition with id=#{id} in presence")

    api =
      state.tracker_mod.find_by_node(id, node_name)
      |> elem(1)
      |> Map.put("active", false)
      |> Map.put("timestamp", Timex.now)

    response = state.tracker_mod.update(id, api)
    {:reply, response, state}
  end

  @spec handle_call({:list_api}, any, state_t) :: {:reply, [api_definition, ...], state_t}
  def handle_call({:list_api}, _from, state) do
    list_of_apis = get_node_name() |> state.tracker_mod.list_by_node
    {:reply, list_of_apis, state}
  end

  @spec handle_call({:get_api}, any, state_t) :: {:reply, api_definition, state_t}
  def handle_call({:get_api, id}, _from, state) do
    node_name = get_node_name()
    api = state.tracker_mod.find_by_node(id, node_name)
    {:reply, api, state}
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
      next_api["ref_number"] < prev_api["ref_number"] -> {:error, :exit}
      next_api["ref_number"] > prev_api["ref_number"] -> {:ok, :update_with_ref}
      true -> eval_data_change(id, prev_api, next_api, state)
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
    prev_apis = state.tracker_mod.find_all(id)
    h_n_of_prev_apis = length(prev_apis) / 2

    equal_apis = prev_apis |> Enum.filter(fn({_key, meta}) ->
      meta |> data_equal?(next_api)
    end)
    n_of_equal_apis = length(equal_apis)

    cond do
      n_of_equal_apis < h_n_of_prev_apis -> {:error, :exit}
      n_of_equal_apis > h_n_of_prev_apis -> {:ok, :update_no_ref}
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
  defp get_node_name, do: Phoenix.PubSub.node_name(Gateway.PubSub)

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

  # Check what is the node origin for given API definition
  # @spec check_node_origin(String.t, api_definition, atom, state_t) :: {atom, atom}
  # defp check_node_origin(id, next_api, node_name, state) do
  #   if node_name != next_api["node_name"] do
  #     state.tracker_mod.find_by_node(id, next_api["node_name"])
  #     |> check_phx_ref(next_api, true)
  #   else
  #     state.tracker_mod.find_by_node(id, node_name)
  #     |> check_phx_ref(next_api, false)
  #   end
  # end

  # Compares phx_ref values from current API and old API to avoid unintentional delete
  # @spec check_phx_ref(nil, api_definition, true) :: {:ok, :untrack}
  # defp check_phx_ref(nil, _next_api, true) do
  #   {:ok, :untrack}
  # end
  # @spec check_phx_ref(nil, api_definition, false) :: {:error, :exit}
  # defp check_phx_ref(nil, _next_api, false) do
  #   {:error, :exit}
  # end
  # @spec check_phx_ref({String.t, api_definition}, api_definition, boolean) :: {atom, atom}
  # defp check_phx_ref({_id, prev_api}, next_api, _different_node) do # TODO: MAYBE USE REF NUMBERS
  #   if prev_api.phx_ref == next_api.phx_ref do
  #     {:ok, :untrack}
  #   else
  #     {:error, :exit}
  #   end
  # end

  @spec read_init_apis() :: [api_definition, ...]
  defp read_init_apis do
    :gateway
    |> :code.priv_dir
    |> Path.join(@config_file)
    |> File.read!
    |> Poison.decode!
  end
end
