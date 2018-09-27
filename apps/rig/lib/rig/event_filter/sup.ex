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

    state = %{extractor_map: %{}}
    send(self(), :reload_config)

    {:ok, state}
  end

  # ---

  @impl GenServer
  def handle_call(
        {:refresh_subscriptions, subscriptions},
        {from, _},
        %{extractor_map: extractor_map} = state
      )
      when is_list(subscriptions) do
    for %Subscription{event_type: event_type} = sub <- subscriptions do
      filter_config = Config.for_event_type(extractor_map, event_type)
      filter = find_or_start_filter_process(event_type, filter_config)
      GenServer.call(filter, {:refresh_subscription, from, sub})
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

  @impl GenServer
  def handle_info(:reload_config, state) do
    %{extractor_config_path_or_json: extractor_config_path_or_json} = config()

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

    {:noreply, %{state | extractor_map: extractor_map}}
  rescue
    err ->
      Logger.error("Failed to reload extractor config: #{inspect(err)}")
      {:noreply, state}
  end

  # ---

  defp reload_filter_config(nil, _), do: nil

  defp reload_filter_config(filter_pid, filter_config) do
    send(filter_pid, {:reload_configuration, filter_config})
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
