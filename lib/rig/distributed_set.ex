defmodule RIG.DistributedSet do
  @moduledoc """
  Distributed grow-only set with per key time-to-live support.
  """
  require Logger
  use GenServer
  import Ex2ms

  alias Timex
  alias UUID

  @type key :: String.t()
  @type uuid :: String.t()
  @type creation_ts :: non_neg_integer()
  @type expiration_ts :: non_neg_integer()
  @type record :: {key(), uuid(), creation_ts(), expiration_ts()}

  @default_ttl_s 86_400
  @sync_interval_s 50
  @cleanup_interval_s 60

  @doc """
  Creates a new distributed set.

  ## Parameters

    - set_name: The name of the distributed set. Multiple instances with the same name
    will synchronize their records with each other.

  """
  def start_link(set_name, opts \\ []) when is_atom(set_name) do
    pg2_group = opts[:pg2_group] || pg2_group_name(set_name)

    state = %{
      name: set_name,
      opts: opts,
      pg2_group: pg2_group,
      ets_table: nil,
      # The ID of the last seen/confirmed record:
      last_record_id: nil
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @doc """
  Add a new record to this set.

  Re-adding already included keys may be used to extend a key's lifetime.

  """
  @spec add(pid | atom, key, non_neg_integer()) :: :ok
  def add(server, key, ttl_s \\ @default_ttl_s) do
    creation_ts = Timex.now() |> serialize_datetime!()
    expiration_ts = Timex.now() |> Timex.shift(seconds: ttl_s) |> serialize_datetime!()
    record = {key, UUID.uuid4(), creation_ts, expiration_ts}
    GenServer.call(server, {:add_from_local, record})
  end

  @doc """
  Check whether this set includes a key or not.

  Returns true if, and only if, the key has been added previously and it has not yet
  expired.

  """
  @spec has?(pid | atom, key, list) :: boolean
  def has?(name, key, opts \\ [])

  def has?(name, key, opts) when is_atom(name) do
    pid = Process.whereis(name)
    has?(pid, key, opts)
  end

  def has?(pid, key, opts) do
    now =
      Timex.now()
      |> Timex.shift(seconds: opts[:shift_time_s] || 0)
      |> serialize_datetime!()

    query =
      fun do
        {^key, _, _, exp} when exp > ^now -> true
      end

    ets_table = ets_table_name(pid)

    case :ets.select_count(ets_table, query) do
      0 -> false
      _ -> true
    end
  end

  # callbacks

  @impl GenServer
  def init(%{name: name, opts: opts, pg2_group: pg2_group} = state) do
    self = self()

    ets_table = opts[:ets_table] || ets_table_name(self)

    # Create the ETS table used to store the records. Note that we're actually using a
    # :bag here rather than a :set. This is because we don't allow exact duplicates, but
    # we're fine with re-adding a key with a later expiration time. As long as at least
    # one record for a key has not expired yet, has(key) will be true.
    :ets.new(ets_table, [:bag, :protected, :named_table, {:read_concurrency, true}])

    # Join group:
    :ok = :pg2.create(pg2_group)
    :ok = :pg2.join(pg2_group, self)

    # Get initial state from a random peer:
    send(self, :sync_with_random_peer)

    # Start cleanup interval:
    send(self, :cleanup)

    Logger.info(fn ->
      pg2 = "pg2=#{inspect(pg2_group)}"
      ets = "ets=#{inspect(ets_table)}"
      "Initialized distributed set #{name} (#{pg2}, #{ets})"
    end)

    {:ok, %{state | ets_table: ets_table}}
  end

  @doc "Handles get_record requests from other nodes."
  @impl GenServer
  def handle_call(
        {:get_records, since_record_id},
        from,
        %{ets_table: ets_table, last_record_id: last_record_id} = state
      ) do
    query =
      case since_record_id do
        nil ->
          fun do
            {_, _, from_ts, _} -> from_ts
          end

        _ ->
          fun do
            {_, id, from_ts, _} when id == ^since_record_id -> from_ts
          end
      end

    records =
      case :ets.select(ets_table, query) do
        [from_ts] -> get_records(ets_table, from_ts)
        _ -> []
      end

    if not Enum.empty?(records),
      do:
        Logger.debug(fn ->
          n_records = length(records)
          from = inspect(from)
          since = "since_record_id=#{inspect(since_record_id)}"
          "Sending #{n_records} records to #{from} (#{since})"
        end)

    reply = {last_record_id, records}
    {:reply, reply, state}
  end

  @doc "Handles adding a record on this node."
  @impl GenServer
  def handle_call(
        {:add_from_local, {_, uuid, _, _} = record},
        _from,
        %{pg2_group: pg2_group, ets_table: ets_table, last_record_id: last_record_id} = state
      ) do
    ets_table
    |> save(record)
    |> broadcast_update(pg2_group, last_record_id)

    {:reply, :ok, %{state | last_record_id: uuid}}
  end

  @doc "Handles adding a record, broadcasted from another node."
  @impl GenServer
  def handle_info(
        {:add_from_remote, {_, incoming_record_id, _, _} = record, remote_previous_record_id},
        %{ets_table: ets_table, last_record_id: local_last_record_id} = state
      ) do
    save(ets_table, record)

    # Only remember this entry as the "last" if we're up-to-date:
    synced_record_id =
      case local_last_record_id do
        nil ->
          # We have no local state yet
          incoming_record_id

        ^remote_previous_record_id ->
          # The nodes are in sync:
          incoming_record_id

        _ ->
          # The nodes are out of sync, so we don't change the last record ID just yet (it
          # will get updated during the next :sync_with_random_peer).
          Logger.info(fn ->
            local = "local=#{local_last_record_id}"
            remote = "remote=#{remote_previous_record_id}"
            "Blacklist nodes out of sync (#{local} vs #{remote})"
          end)

          local_last_record_id
      end

    {:noreply, %{state | last_record_id: synced_record_id}}
  end

  @doc """
  Asks a random peer for missing records.

  Records are missing on startup, but there could also be a gap caused by a temporary
  network split.
  """
  @impl GenServer
  def handle_info(
        :sync_with_random_peer,
        %{pg2_group: pg2_group, ets_table: ets_table, last_record_id: last_record_id} = state
      ) do
    state =
      with {:ok, peer} <- choose_random_peer(pg2_group),
           {:ok, {remote_last_record_id, records}} <- get_records_from_peer(peer, last_record_id) do
        for record <- records, do: save(ets_table, record)
        %{state | last_record_id: remote_last_record_id}
      else
        {:error, :no_peer_available} ->
          state

        {:error, {:timeout, peer}} ->
          Logger.warn(fn -> "Call to #{inspect(peer)} timed out" end)
          state
      end

    next_sync_in_ms = (@sync_interval_s + :rand.uniform(10) - 5) * 1_000
    Process.send_after(self(), :sync_with_random_peer, next_sync_in_ms)
    {:noreply, state}
  end

  @doc "Remove expired records."
  @impl GenServer
  def handle_info(:cleanup, %{ets_table: ets_table} = state) do
    remove_expired_records(ets_table)
    Process.send_after(self(), :cleanup, @cleanup_interval_s * 1_000)
    {:noreply, state}
  end

  # private

  defp remove_expired_records(ets_table) do
    now = Timex.now() |> serialize_datetime!()

    match_spec =
      fun do
        {_, _, _, exp} when exp < ^now -> true
      end

    n_deleted = :ets.select_delete(ets_table, match_spec)

    if n_deleted > 0 do
      Logger.debug(fn -> "Removed #{n_deleted} expired records" end)
    end

    n_deleted
  end

  defp get_records(ets_table, from_ts) do
    query =
      fun do
        {_, _, creation_ts, _} = record when creation_ts >= ^from_ts -> record
      end

    :ets.select(ets_table, query)
  end

  defp get_records_from_peer(peer, last_record_id) do
    {remote_last_record_id, records} = GenServer.call(peer, {:get_records, last_record_id})
    {:ok, {remote_last_record_id, records}}
  catch
    :exit, {:timeout, _} ->
      {:error, {:timeout, peer}}
  end

  defp choose_random_peer(pg2_group) do
    self = self()

    peer =
      pg2_group
      |> :pg2.get_members()
      |> Enum.reject(&(&1 == self))
      |> Enum.random()

    {:ok, peer}
  rescue
    _ in Enum.EmptyError -> {:error, :no_peer_available}
  end

  defp broadcast_update(record, pg2_group, previous_record_id) do
    self = self()

    for peer <- :pg2.get_members(pg2_group), peer != self do
      send(peer, {:add_from_remote, record, previous_record_id})
    end
  end

  defp save(ets_table, record) do
    true = :ets.insert(ets_table, record)
    Logger.debug(fn -> "Added record: #{inspect(record)}" end)
    record
  end

  defp pg2_group_name(name) when is_atom(name), do: {:distributed_set, name}

  defp ets_table_name(pid),
    do: "distributed_set_#{:erlang.pid_to_list(pid)}" |> String.to_atom()

  @spec serialize_datetime!(Timex.DateTime.t()) :: String.t()
  defp serialize_datetime!(dt) do
    Timex.format!(dt, "{s-epoch}")
  end
end
