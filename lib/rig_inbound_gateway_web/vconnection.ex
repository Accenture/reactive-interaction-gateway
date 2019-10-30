defmodule RigInboundGatewayWeb.VConnection do
  @moduledoc """
  The VConnection acts as an abstraction for the actual connections.

  It monitors the processes, sends out heartbeats and subscription refreshes, handles heartbeat and the general state of each connection.
  """

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.Events
  alias RigInboundGatewayWeb.EventBuffer

  require Logger

  use GenServer
  use Rig.Config, [:idle_connection_timeout]

  #TEMP UNTIL WE ACTUALLY IMPLEMENT lasteventid
  @buffer_size 1

  def start(pid, subscriptions, heartbeat_interval_ms, subscription_refresh_interval_ms) do
    GenServer.start(__MODULE__,
    %{
      target_pid: pid,
      subscriptions: subscriptions,
      heartbeat_interval_ms: heartbeat_interval_ms,
      subscription_refresh_interval_ms: subscription_refresh_interval_ms,
      kill_timer: nil,
      monitor: nil,
      event_buffer: EventBuffer.new(@buffer_size)
    })
  end

  def start(heartbeat_interval_ms, subscription_refresh_interval_ms) do
    start(nil, [], heartbeat_interval_ms, subscription_refresh_interval_ms)
  end

  def start_with_timeout(heartbeat_interval_ms, subscription_refresh_interval_ms) do
    {:ok, vconnection_pid} = start(heartbeat_interval_ms, subscription_refresh_interval_ms)
    send vconnection_pid, :vconnection_timeout

    {:ok, vconnection_pid}
  end

  @impl true
  def init(state) do
    # TODO: Publish connect event

    Logger.debug(fn -> "New VConnection initialized #{inspect(self())}" end)

    # We register subscriptions:
    send self(), {:set_subscriptions, state.subscriptions}

    # We schedule the initial heartbeat:
    Process.send_after(self(), :heartbeat, state.heartbeat_interval_ms)

    # And the initial subscription refresh:
    Process.send_after(self(), :refresh_subscriptions, state.subscription_refresh_interval_ms)

    if state.target_pid do
      {:ok, create_monitor(state)}
    else
      {:ok, state}
    end
  end

  @impl true
  def handle_call(:reconnect, from, state) do
    if state.kill_timer do
      Process.cancel_timer(state.kill_timer)
      Logger.debug(fn -> "Kill-timer #{inspect(state.kill_timer)} stopped" end)
    end

    if state.monitor do
      # Demonitor old connection in case we replace an existing connection
      Process.demonitor(state.monitor)
    end

    # In case an old connection exists, kill it off before replacing it
    send! state.target_pid, :close

    {from_pid, _} = from

    # Switch target pid
    state = Map.put(state, :target_pid, from_pid)
    # Register new monitor
    |> create_monitor

    Logger.debug(fn -> "Client #{inspect(from_pid)} reconnected" end)

    # TODO: Schedule send of all missed events
    # TODO: Publish reconnect event
    {:reply, {:ok, self()}, state}
  end

  @impl true
  def handle_info(:set_subscriptions, state) do
    # Register subscriptions
    send self(), {:set_subscriptions, state.subscriptions}
    {:noreply, state}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    # Send heartbeat to the connection
    send! state.target_pid, {:forward, :heartbeat}

    # And schedule the next one:
    Process.send_after(self(), :heartbeat, state.heartbeat_interval_ms)
    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh_subscriptions, state) do
    EventFilter.refresh_subscriptions(state.subscriptions, [])

    # And schedule the next one:
    Process.send_after(self(), :refresh_subscriptions, state.subscription_refresh_interval_ms)
    {:noreply, state}
  end

  @impl true
  def handle_info(%CloudEvent{} = event, state) do
    Logger.debug(fn -> "event: " <> inspect(event) end)
    send! state.target_pid, {:forward, event}

    # Buffer event so we can send it to the client as soon as there's a reconnect
    state = Map.put(state, :event_buffer, state.event_buffer |> EventBuffer.add_event(event))
    {:noreply, state}
  end

  @impl true
  def handle_info({:set_subscriptions, subscriptions}, state) do
    Logger.debug(fn -> "subscriptions: " <> inspect(subscriptions) end)

    # Trigger immediate refresh:
    EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)

    # Replace current subscriptions:
    state = Map.put(state, :subscriptions, subscriptions)

    send! state.target_pid, {:forward, Events.subscriptions_set(subscriptions)}

    {:noreply, state}
  end

  @impl true
  def handle_info({:session_killed, session_id}, state) do
    # Session kill must be handled by the connection
    send! state.target_pid, {:session_killed, session_id}

    # Since the session was killed, there's no need for a VConnection anymore
    send self(), :kill
    {:noreply, state}
  end

  @impl true
  def handle_info(:kill, _state) do
    Logger.debug(fn -> "Virtual Connection went down #{inspect(self())}" end)
    Process.exit(self(), :kill)
  end

  @impl true
  def handle_info(:vconnection_timeout, state) do
    Logger.debug(fn -> "Connection initialized, timeout starting..." end)

    {:noreply, start_timer(state)}
  end

  @impl true
  def handle_info(:kill_connection, state) do
    send! state.target_pid, :close
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    Logger.debug(fn -> "Connection went down #{inspect(pid)}" end)

    # TODO: Publish down event

    {:noreply, start_timer(state)}
  end

  defp create_monitor(state) do
    monitor = Process.monitor(state.target_pid)
    Map.put(state, :monitor, monitor)
  end

  defp send!(pid, data)
  defp send!(nil, _data), do: nil
  defp send!(pid, data), do: send pid, data

  defp start_timer(state) do
    %{idle_connection_timeout: delay} = config()
    delay = String.to_integer(delay)
    timer = Process.send_after(self(), :kill, delay)
    Map.put(state, :kill_timer, timer)
  end
end
