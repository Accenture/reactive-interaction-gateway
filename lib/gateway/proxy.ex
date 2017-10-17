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
  }

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

  def get_api(id) do
    GenServer.call(Gateway.Proxy, {:get_api, id})
  end

  @spec add_api(pid | atom, String.t, api_definition) :: pid
  def add_api(server, id, api) do
    GenServer.cast(server, {:add_api, id, api})
    server  # allow for chaining calls
  end

  def update_api(server, id, api) do
    GenServer.cast(server, {:update_api, id, api})
    server  # allow for chaining calls
  end

  def delete_api(server, id) do
    GenServer.cast(server, {:delete_api, id})
    server  # allow for chaining calls
  end

  def handle_join_api(server, id, api) do
    GenServer.cast(server, {:handle_join_api, id, api})
    server  # allow for chaining calls
  end

  def handle_leave_api(server, id, api) do
    GenServer.cast(server, {:handle_leave_api, id, api})
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

  @spec handle_cast({:add_api, String.t, api_definition}, state_t) :: {:noreply, state_t}
  def handle_cast({:add_api, id, api}, state) do
    Logger.info("Adding new API definition with id=#{id} to presence")

    meta_info = %{"ref_number" => 0, "timestamp" => Timex.now}
    api_with_meta_info = add_meta_info(api, meta_info)

    state.tracker_mod.track(id, api_with_meta_info)
    {:noreply, state}
  end

  def handle_cast({:update_api, id, api}, state) do
    Logger.info("Updating API definition with id=#{id} in presence")
    # TODO: should get by ID, merge and update ref + timestamp

    meta_info = %{"ref_number" => api["ref_number"] + 1, "timestamp" => Timex.now}
    api_with_meta_info = add_meta_info(api, meta_info)

    state.tracker_mod.update(id, api_with_meta_info)
    {:noreply, state}
  end

  def handle_cast({:delete_api, id}, state) do
    Logger.info("Deleting API definition with id=#{id} from presence")

    state.tracker_mod.untrack(id)
    {:noreply, state}
  end

  def handle_cast({:handle_join_api, id, api}, state) do
    node_name = get_node_name()
    Logger.info("Handling JOIN differential for API definition with id=#{id} for node=#{node_name}")

    prev_api = state.tracker_mod.find(id, node_name)
    IO.puts "PREV API"
    IO.inspect prev_api
    IO.puts "NEXT API"
    IO.inspect api

    case compare_api(id, prev_api, api, state) do
      {:error, :exit} ->
        Logger.debug("There is already most recent API definition with id=#{id} in presence")
      {:ok, :track} ->
        meta_info = %{"ref_number" => 0, "timestamp" => Timex.now}
        api_with_meta_info = add_meta_info(api, meta_info)

        state.tracker_mod.track(id, api_with_meta_info)
      {:ok, :update_no_ref} ->
        Logger.debug("API definition with id=#{id} adopted new version with no REF update")
        state.tracker_mod.update(id, add_meta_info(api))
      {:ok, :update_with_ref} ->
        Logger.debug("API definition with id=#{id} adopted new version with REF update")

        prev_api_data = elem(prev_api, 1)
        meta_info = %{"ref_number" => prev_api_data["ref_number"] + 1}
        api_with_meta_info = add_meta_info(api, meta_info)
  
        state.tracker_mod.update(id, api_with_meta_info)
    end

    {:noreply, state}
  end

  def handle_cast({:handle_leave_api, id, api}, state) do
    node_name = get_node_name()
    Logger.info("Handling LEAVE differential for API definition with id=#{id} for node=#{node_name}")

    case check_node_origin(id, api, node_name, state) do
      {:error, :exit} ->
        Logger.debug("Blocked unwanted deletion of API definition with id=#{id} from presence")
      {:ok, :untrack} ->
        Logger.debug("DIFF DELETE of API definition with id=#{id} from presence")
        state.tracker_mod.untrack(id)
    end

    {:noreply, state}
  end

  @spec handle_call({:list_api}, any, state_t) :: {:reply, state_t}
  def handle_call({:list_api}, _from, state) do
    list_of_apis = state.tracker_mod.list
    {:reply, list_of_apis, state}
  end

  def handle_call({:get_api, id}, _from, state) do
    node_name = get_node_name()
    api = state.tracker_mod.find(id, node_name)
    {:reply, api, state}
  end

  # TEMPORARY FUNCTIONS => SHOULD BE MOVED ELSEWHERE PROLLY

  defp compare_api(_id, nil, _next_api, _state), do: {:ok, :track}
  defp compare_api(id, {id, prev_api}, next_api, state) do
    IO.inspect prev_api["ref_number"]
    IO.inspect next_api["ref_number"]

    cond do
      next_api["ref_number"] < prev_api["ref_number"] -> {:error, :exit}
      next_api["ref_number"] > prev_api["ref_number"] -> {:ok, :update_with_ref}
      true -> eval_data_change(id, prev_api, next_api, state)
    end
  end

  defp eval_data_change(id, prev_api, next_api, state) do
    prev_apis = state.tracker_mod.find_all(id)
    IO.puts "OLD APIS"
    IO.inspect prev_apis
    h_n_of_prev_apis = length(prev_apis) / 2
    next_api_without_meta = next_api |> remove_meta_info
    different_apis = prev_apis |> Enum.filter(fn({_key, meta}) ->
      meta
      |> remove_meta_info
      |> Map.equal?(next_api_without_meta)
      |> Kernel.not
    end)
    n_of_different_apis = length(different_apis)

    IO.puts "NUMBER OF CHANGED APIS #{n_of_different_apis}"
    IO.puts "DOES AT LEAST HALF OF NODES CHANGE #{n_of_different_apis >= h_n_of_prev_apis}"

    cond do
      n_of_different_apis < h_n_of_prev_apis -> {:error, :exit}
      n_of_different_apis > h_n_of_prev_apis -> {:ok, :update_no_ref}
      true ->
        next_api["timestamp"]
        |> Timex.after?(prev_api["timestamp"])
        |> eval_time
    end
  end

  defp eval_time(false) do
    IO.puts "NEXT TIMESTAMP IS OLDER OR SAME AS PREV TIMESTAMP"
    {:error, :exit}
  end
  defp eval_time(true) do
    IO.puts "NEXT TIMESTAMP IS NEWER THAN PREV TIMESTAMP"
    {:ok, :update_no_ref}
  end

  defp get_node_name, do: Phoenix.PubSub.node_name(Gateway.PubSub)
  
  defp add_meta_info(api, meta_info \\ %{}) do
    api
    |> Map.merge(meta_info)
    |> Map.put("node_name", get_node_name())
  end

  defp remove_meta_info(api) do
    api
    |> Map.delete(:phx_ref)
    |> Map.delete(:phx_ref_prev)
    |> Map.delete("node_name")
    |> Map.delete("timestamp")
  end

  defp check_node_origin(id, next_api, node_name, state) do
    if node_name != next_api["node_name"] do
      IO.puts "DIFFERENT NODE"
      state.tracker_mod.find(id, next_api["node_name"])
      |> check_phx_ref(next_api, true)
    else
      IO.puts "SAME NODE"
      state.tracker_mod.find(id, node_name)
      |> check_phx_ref(next_api, false)
    end
  end

  defp check_phx_ref(nil, _next_api, true) do
    IO.puts "DIFFERENT NODE - NO API FOR DIFFERENT NODE IN MY PRESENCE, KILL OURS"
    {:ok, :untrack}
  end
  defp check_phx_ref(nil, _next_api, false) do
    IO.puts "SAME NODE - NO API FOR THIS NODE IN MY PRESENCE, SKIP UNTRACK"
    {:error, :exit}
  end
  defp check_phx_ref({_id, prev_api}, next_api, _different_node) do # TODO: MAYBE USE REF NUMBERS
    if prev_api.phx_ref == next_api.phx_ref do
      IO.puts "PHX_REF are same"
      {:ok, :untrack}
    else
      IO.puts "PHX_REF are different"
      {:error, :exit}
    end
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
