defmodule Rig.EventFilter.Sup do
  @moduledoc """
  Starts filter processes on the local node on demand.

  Each node should run exactly one EventFilter Supervisor.
  """
  require Logger
  use GenServer
  use Rig.Config, [:extractor_config_path_or_json]

  alias Rig.EventFilter.Config
  alias Rig.EventFilter.Server, as: Filter
  alias Rig.Subscription

  @pg2_group "#{__MODULE__}"

  # ---

  def processes do
    :ok = :pg2.create(@pg2_group)
    :pg2.get_members(@pg2_group)
  end

  # ---

  def start_link(opts \\ []) do
    opts = Keyword.merge([name: __MODULE__], opts)
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  # ---

  @impl GenServer
  def init(:ok) do
    :ok = :pg2.create(@pg2_group)
    :ok = :pg2.join(@pg2_group, self())

    %{extractor_config_path_or_json: extractor_config_path_or_json} = config()

    state =
      case reload_config(extractor_config_path_or_json) do
        nil -> %{extractor_map: %{}}
        extractor_map -> %{extractor_map: extractor_map}
      end

    {:ok, state}
  end

  # ---

  @impl GenServer
  def handle_call(
        {:refresh_subscriptions, subscriptions, prev_subscriptions},
        _from = {socket_pid, _tag},
        %{extractor_map: extractor_map} = state
      )
      when is_list(subscriptions) and is_list(prev_subscriptions) do
    subs_by_eventtype =
      subscriptions
      |> Enum.group_by(fn %Subscription{event_type: event_type} -> event_type end)

    for {event_type, subs} <- subs_by_eventtype do
      filter_config = Config.for_event_type(extractor_map, event_type)
      filter = find_or_start_filter_process(event_type, filter_config)
      GenServer.call(filter, {:refresh_subscriptions, socket_pid, subs})
    end

    # If a subscription for an event type has been removed completely, the respective
    # filter process has to be notified; otherwise, events will still be delivered to
    # the connection process.
    prev_subscriptions
    |> Enum.map(fn %Subscription{event_type: event_type} -> event_type end)
    # If it's in subs_by_eventtype the filter process already knows..
    |> Enum.reject(fn event_type -> Map.has_key?(subs_by_eventtype, event_type) end)
    # Notify the respective filter processes:
    |> Enum.each(fn event_type ->
      # If we can find a filter for this type, we ask it to clear all subscriptions for socket_pid:
      case get_filter_pid(event_type) do
        nil -> :ignore
        filter -> GenServer.call(filter, {:refresh_subscriptions, socket_pid, _subs = []})
      end
    end)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:reload_config, _from, state) do
    %{extractor_config_path_or_json: extractor_config_path_or_json} = config()

    state =
      case reload_config(extractor_config_path_or_json) do
        nil -> state
        extractor_map -> %{state | extractor_map: extractor_map}
      end

    {:reply, :ok, state}
  end

  # ---

  @impl GenServer
  def handle_info({:DOWN, ref, :process, object, reason}, state) do
    Logger.error("Filter #{inspect(object)}/ref=#{inspect(ref)} died: #{inspect(reason)}")
    {:noreply, state}
  end

  # ---

  defp reload_config(extractor_config_path_or_json)

  defp reload_config(nil), do: nil

  defp reload_config(extractor_config_path_or_json) do
    Logger.debug(fn ->
      "Reloading extractor config from #{String.replace(extractor_config_path_or_json, "\n", "")}"
    end)

    {:ok, extractor_map} = Config.new(extractor_config_path_or_json)

    for {event_type, filter_config} <- extractor_map do
      # The config should be checked regardless of whether the filter is alive or not:
      :ok = Config.check_filter_config(filter_config)

      event_type
      |> get_filter_pid()
      |> reload_filter_config(filter_config)
    end

    extractor_map
  rescue
    err ->
      Logger.error(
        "Failed to reload extractor config: #{inspect(err)}\n#{inspect(__STACKTRACE__)}"
      )

      nil
  end

  # ---

  defp reload_filter_config(nil, _), do: nil

  defp reload_filter_config(filter_pid, filter_config) do
    GenServer.call(filter_pid, {:reload_configuration, filter_config})
  end

  # ---

  defp find_or_start_filter_process(event_type, filter_config) do
    event_type
    |> get_filter_pid()
    |> case do
      nil ->
        {:ok, pid} = Filter.start(event_type, filter_config)
        _ref = Process.monitor(pid)
        pid

      pid ->
        pid
    end
  end

  # ---

  defp get_filter_pid(event_type) do
    event_type
    |> Filter.process()
    |> Process.whereis()
  end
end
