defmodule Rig.EventFilter.Sup do
  @moduledoc """
  Starts filter processes on the local node on demand.

  Each node should run exactly one EventFilter Supervisor.
  """
  require Logger
  use GenServer

  alias Rig.EventFilter.Server, as: Filter
  alias Rig.Subscription

  @pg2_group "#{__MODULE__}"

  def processes do
    :ok = :pg2.create(@pg2_group)
    :pg2.get_members(@pg2_group)
  end

  def start_link(opts \\ []) do
    state = %{}
    opts = Keyword.merge([name: __MODULE__], opts)
    GenServer.start_link(__MODULE__, state, opts)
  end

  @impl GenServer
  def init(state) do
    :ok = :pg2.create(@pg2_group)
    :ok = :pg2.join(@pg2_group, self())
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:refresh_subscriptions, subscriptions}, {from, _}, state)
      when is_list(subscriptions) do
    for %Subscription{event_type: event_type} = sub <- subscriptions do
      event_type
      |> find_or_start_filter_process()
      |> GenServer.call({:refresh_subscription, from, sub})
    end

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, object, reason}, state) do
    Logger.error("Filter #{inspect(object)}/ref=#{inspect(ref)} died: #{inspect(reason)}")
    {:noreply, state}
  end

  defp find_or_start_filter_process(event_type) do
    event_type
    |> Filter.process()
    |> Process.whereis()
    |> case do
      nil ->
        # TODO read config from disk?
        config = %{}
        {:ok, pid} = Filter.start(event_type, config)
        _ref = Process.monitor(pid)
        pid

      pid ->
        pid
    end
  end
end
