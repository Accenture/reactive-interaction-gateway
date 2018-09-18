defmodule Rig.EventFilter.Server do
  @moduledoc """
  Filter for the event subscription mechanism.

  For each event type, on each node, there is exactly one EventFilter (Server). The
  Filter keeps track of subscriptions. Subscriptions have a time-to-live, that is, if
  they're not renewed for some time, the Filter will remove them eventually.
  """
  require Logger
  use GenServer

  alias JSONPointer
  alias Timex

  alias Rig.EventFilter.Config
  alias Rig.EventFilter.MatchSpec.ConfigUpdater
  alias Rig.EventFilter.MatchSpec.SubscriptionMatcher
  alias Rig.Subscription

  @default_subscription_ttl_s 60
  @cleanup_interval_ms 90_000
  @index_field "stable_field_index"

  # ---

  def process(event_type) do
    "#{__MODULE__}.#{event_type}" |> String.to_atom()
  end

  # ---

  @type event_type :: String.t()

  @spec start(event_type, Config.event_type_config(), list) :: {:ok, pid}
  def start(event_type, config, opts \\ []),
    do: do_start(event_type, config, opts, &GenServer.start/3)

  @spec start_link(event_type, Config.event_type_config(), list) :: {:ok, pid}
  def start_link(event_type, config, opts \\ []),
    do: do_start(event_type, config, opts, &GenServer.start_link/3)

  defp do_start(event_type, config, opts, start_fun) do
    :ok = Config.check_filter_config(config)

    state = %{
      event_type: event_type,
      subscription_ttl_s: opts[:subscription_ttl_s] || @default_subscription_ttl_s,
      config: config,
      fields: fields_from_config(config),
      debug?: opts[:debug?] || false
    }

    opts = Keyword.merge([name: process(event_type)], opts)
    start_fun.(__MODULE__, state, opts)
  end

  # ---

  @impl GenServer
  def init(%{event_type: event_type, debug?: debug?} = state) do
    Logger.debug("New Filter #{inspect(self())} for #{inspect(state.event_type)}")

    # The ETS table is owned by self and destroyed automatically when self dies.
    table_name = "subscriptions_for_#{event_type}" |> String.to_atom()
    ets_access_type = if debug?, do: :public, else: :protected
    subscription_table = :ets.new(table_name, [:bag, ets_access_type])

    # Schedule periodic ETS cleanup:
    Process.send_after(self(), :cleanup, @cleanup_interval_ms)

    state =
      state
      |> Map.put(:subscription_table, subscription_table)

    {:ok, state}
  end

  # ---

  @impl GenServer
  def handle_call(
        {:refresh_subscription, conn_pid, %Subscription{} = subscription},
        _from,
        %{
          event_type: event_type,
          subscription_table: subscription_table,
          subscription_ttl_s: ttl_s,
          fields: fields
        } = state
      ) do
    # Only handle subscriptions for event types we're responsible for (not supposed to happen):
    ^event_type = subscription.event_type
    expiration_ts = Timex.now() |> Timex.shift(seconds: ttl_s) |> as_epoch()
    add_to_table(subscription_table, conn_pid, expiration_ts, fields, subscription.constraints)
    {:reply, :ok, state}
  end

  # ---

  @impl GenServer
  def handle_cast(
        {:cloud_event, event},
        %{
          subscription_table: subscription_table,
          config: config,
          fields: fields
        } = state
      ) do
    get_value_in_event = get_extractor(config, event)
    match_spec = SubscriptionMatcher.match_spec(fields, get_value_in_event)

    conn_pid_set =
      subscription_table
      |> :ets.select(match_spec)
      |> MapSet.new()

    for pid <- conn_pid_set do
      send(pid, {:cloud_event, event})
    end

    {:noreply, state}
  end

  # ---

  @impl GenServer
  def handle_info(:cleanup, state) do
    remove_expired_records(state)
    Process.send_after(self(), :cleanup, @cleanup_interval_ms)
    {:noreply, state}
  end

  # ---

  @impl GenServer
  def handle_info(
        {:reload_configuration, new_config},
        %{subscription_table: subscription_table, fields: cur_fields} = state
      ) do
    new_fields = fields_from_config(new_config)

    case Config.check_filter_config(new_config) do
      :ok ->
        # Any new fields are added to the table as nil (= wildcard) constraint:
        add_wildcards_to_table(subscription_table, length(cur_fields), length(new_fields))
        {:noreply, %{state | config: new_config, fields: new_fields}}

      err ->
        Logger.error("Not loading invalid config '#{inspect(new_config)}' due to #{inspect(err)}")
        {:noreply, state}
    end
  end

  # ---

  defp fields_from_config(config) do
    config
    |> Map.keys()
    |> Enum.sort_by(&get_in(config, [&1, @index_field]))
  end

  # ---

  defp add_wildcards_to_table(table, n_cur_fields, n_new_fields)
       when n_new_fields > n_cur_fields do
    match_spec = ConfigUpdater.match_spec(n_cur_fields, n_new_fields)
    :ets.select_replace(table, match_spec)
  end

  defp add_wildcards_to_table(_, _, _), do: nil

  # ---

  defp add_to_table(table, conn_pid, expiration_ts, fields, constraints)

  # No constraints can be translated to a single, match-anything clause:
  defp add_to_table(table, conn_pid, expiration_ts, fields, []) do
    wildcard = %{}
    constraints = [wildcard]
    add_to_table(table, conn_pid, expiration_ts, fields, constraints)
  end

  # Each constraint is added to the table individually. Note that constraints that do
  # not relate to a known field are simply ignored (any deduplication is done by
  # `:ets.insert/2`). This happens when adding a field to another node, but not
  # restarting this node; then the "newer" node forwards the subscription request with
  # the additional field, but this node does not yet know about it. Only after this node
  # reloads its configuration (on startup), it will consider the additional constraints.
  # Consequently, clients receive at least the events they are subscribed to, but they
  # should be prepared to drop additional events (those that should've been filtered out
  # by the - ignored - constraint).
  defp add_to_table(table, conn_pid, expiration_ts, fields, constraints) do
    for constraint <- constraints do
      ordered_constraints = for field <- fields, do: Map.get(constraint, field)

      record =
        ([conn_pid, expiration_ts] ++ ordered_constraints)
        |> List.to_tuple()

      true = :ets.insert(table, record)
    end
  end

  # ---

  def remove_expired_records(%{
        subscription_table: ets_table,
        fields: fields
      }) do
    now = Timex.now() |> as_epoch()

    # The tuple size must match the number of fields + 2:
    n_fields = length(fields)
    match_tuple = List.to_tuple([:_, :"$1"] ++ List.duplicate(:_, n_fields))
    # We select all records with expiration_ts before (= smaller than) now:
    match_spec = [{match_tuple, [{:"=<", :"$1", now}], [true]}]

    n_deleted = :ets.select_delete(ets_table, match_spec)

    # if n_deleted > 0,
    #   do: Logger.debug(fn -> "Removed #{n_deleted} expired #{event_type} subscriptions" end)

    n_deleted
  end

  # ---

  @spec as_epoch(Timex.DateTime.t()) :: integer
  defp as_epoch(dt) do
    dt
    |> Timex.format!("{s-epoch}")
    |> String.to_integer()
  end

  # ---

  # Creates a closure for obtaining field values from a given event.
  defp get_extractor(config, event) do
    fn field ->
      json_pointer = get_in(config, [field, "event", "json_pointer"])
      extract_value(event, json_pointer)
    end
  end

  # ---

  defp extract_value(event, json_pointer) do
    case JSONPointer.get(event, json_pointer) do
      {:ok, value} ->
        value

      err ->
        Logger.warn(fn -> "#{inspect(err)} at #{json_pointer}: #{inspect(event)}" end)
        nil
    end
  end
end
