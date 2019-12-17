defmodule RigInboundGatewayWeb.VConnection do
  @moduledoc """
  The VConnection acts as an abstraction for the actual connections.

  It monitors the processes, sends out heartbeats and subscription refreshes, handles heartbeat and the general state of each connection.
  """

  alias RIG.DistributedMap

  alias Rig.Connection.Codec
  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.Events
  alias RigInboundGatewayWeb.EventBuffer

  require Logger

  use GenServer
  use Rig.Config, [:idle_connection_timeout, :connection_buffer_size, :resend_interval]

  @metadata_ttl_s 60

  def start(pid, subscriptions, metadata, heartbeat_interval_ms, subscription_refresh_interval_ms) do
    {_, data} = metadata
    {metadata, indexed_fields} = case data do
      {a, b} -> {a, b}
      _ -> {nil, nil}
    end

    %{connection_buffer_size: buffer_size} = config()
    buffer_size = String.to_integer(buffer_size)

    GenServer.start(
      __MODULE__,
      %{
        target_pid: pid,
        subscriptions: subscriptions,
        metadata: metadata,
        indexed_fields: indexed_fields,
        heartbeat_interval_ms: heartbeat_interval_ms,
        subscription_refresh_interval_ms: subscription_refresh_interval_ms,
        kill_timer: nil,
        monitor: nil,
        event_buffer: EventBuffer.new(buffer_size)
      }
    )
  end

  def start(heartbeat_interval_ms, subscription_refresh_interval_ms) do
    start(nil, [], {:error, nil}, heartbeat_interval_ms, subscription_refresh_interval_ms)
  end

  def start_with_timeout(heartbeat_interval_ms, subscription_refresh_interval_ms) do
    {:ok, vconnection_pid} = start(heartbeat_interval_ms, subscription_refresh_interval_ms)
    send(vconnection_pid, :vconnection_timeout)

    {:ok, vconnection_pid}
  end

  @impl true
  def init(state) do
    Logger.debug(fn -> "New VConnection initialized #{inspect(self())}" end)

    # We register subscriptions:
    send(self(), {:set_subscriptions, state.subscriptions})

    # And metadata:
    send(self(), {:set_metadata, state.metadata, state.indexed_fields, true})

    # We schedule the initial heartbeat:
    Process.send_after(self(), :heartbeat, state.heartbeat_interval_ms)

    # And the initial subscription refresh:
    Process.send_after(self(), :refresh_subscriptions, state.subscription_refresh_interval_ms)

    # And the initial metadata refresh:
    Process.send_after(self(), :refresh_metadata, @metadata_ttl_s * 1000)

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
    send!(state.target_pid, :close)

    {from_pid, _} = from

    # Switch target pid
    state =
      Map.put(state, :target_pid, from_pid)
      # Register new monitor
      |> create_monitor

    Logger.debug(fn -> "Client #{inspect(from_pid)} reconnected" end)

    {:reply, {:ok, self()}, state}
  end

  @impl true
  def handle_call(:is_online, _from, state) do
    if state.target_pid != nil do
      {:reply, Process.alive?(state.target_pid), state}
    else
      {:reply, false, state}
    end
  end

  @impl true
  def handle_info({:schedule_missing, last_event_id}, state) do
    %{resend_interval: interval} = config()
    interval = String.to_integer(interval)

    case EventBuffer.events_since(state.event_buffer, last_event_id) do
      {:ok, [events: []]} ->
        Logger.debug(fn -> "Received last_event_id but have no events to return #{inspect(self())}" end)

      {:ok, [events: events, last_event_id: _last_event_id]} ->
        Logger.debug(fn -> "Scheduling resending of buffered events #{inspect(self())}" end)
        Process.send_after(self(), {:send_missing, events}, interval)

      {:no_such_event, [not_found_id: _not_found_id, last_event_id: _last_event_id]} ->
        Logger.debug(fn -> "Received last_event_id but it is unknown #{inspect(self())}" end)
    end

    {:noreply, state}
  end

  @doc """
  ### Dirty testing

    CONN_TOKEN=$(http :4000/_rig/v1/connection/init)
    SUBSCRIPTIONS='{"subscriptions":[{"eventType":"chatroom_message"}]}'
    http put ":4000/_rig/v1/connection/sse/${CONN_TOKEN}/subscriptions" <<<"$SUBSCRIPTIONS"
    http post :4000/_rig/v1/events specversion=0.2 type=chatroom_message id=eventa source=tutorial
    http post :4000/_rig/v1/events specversion=0.2 type=chatroom_message id=eventb source=tutorial
    http post :4000/_rig/v1/events specversion=0.2 type=chatroom_message id=eventc source=tutorial
    http post :4000/_rig/v1/events specversion=0.2 type=chatroom_message id=eventd source=tutorial
    http --stream ":4000/_rig/v1/connection/sse?last_event_id=eventb&connection_token=$CONN_TOKEN"
  """
  @impl true
  def handle_info({:send_missing, [event | events]}, state) do
    %{resend_interval: interval} = config()
    interval = String.to_integer(interval)

    send self(), event

    if events != [] do
      # Schedule send of events that are left
      Process.send_after(self(), {:send_missing, events}, interval)
    end
    {:noreply, state}
  end

  @impl true
  def handle_info({:set_metadata, metadata, indexed_fields, msg}, state) do
    unless metadata == nil or indexed_fields == nil do
      # Store metadata
      indexed_fields
      |> Enum.each(fn x ->
        # When accessing metadata, the controller sends a request to the VConnection PID
        # This way, we can also see if a user is online
        DistributedMap.add(:metadata, x, Codec.serialize(self()) , @metadata_ttl_s)
      end)

      if msg do
        event = Events.metadata_set(metadata)

        send! state.target_pid, {:forward, event}
      end
    end

    # Replace current Metadata
    state = Map.put(state, :metadata, metadata)
    state = Map.put(state, :indexed_fields, indexed_fields)

    {:noreply, state}
  end

  @impl true
  def handle_info({:set_metadata, msg}, state) do
    # Register metadata
    send(self(), {:set_metadata, state.metadata, state.indexed_fields, msg})

    {:noreply, state}
  end

  @impl true
  def handle_info(:set_subscriptions, state) do
    # Register subscriptions
    send(self(), {:set_subscriptions, state.subscriptions})
    {:noreply, state}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    # Send heartbeat to the connection
    send!(state.target_pid, {:forward, :heartbeat})

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
  def handle_info(:refresh_metadata, state) do
    unless state.metadata == nil or state.indexed_fields == nil do
      Logger.debug(fn -> "Metadata was refreshed! #{inspect(self())}" end)
      send self(), {:set_metadata, false}
    end

    # And schedule the next one:
    Process.send_after(self(), :refresh_metadata, @metadata_ttl_s * 1000)
    {:noreply, state}
  end

  @impl true
  def handle_info(%CloudEvent{} = event, state) do
    Logger.debug(fn -> "event: " <> inspect(event) end)
    send!(state.target_pid, {:forward, event})

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

    send!(state.target_pid, {:forward, Events.subscriptions_set(subscriptions)})

    {:noreply, state}
  end

  @impl true
  def handle_info({:session_killed, session_id}, state) do
    # Session kill must be handled by the connection
    send!(state.target_pid, {:session_killed, session_id})

    # Since the session was killed, there's no need for a VConnection anymore
    send(self(), :kill)
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
    send!(state.target_pid, :close)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    Logger.debug(fn -> "Connection went down #{inspect(pid)}" end)
    {:noreply, start_timer(state)}
  end

  defp create_monitor(state) do
    monitor = Process.monitor(state.target_pid)
    Map.put(state, :monitor, monitor)
  end

  defp send!(pid, data)
  defp send!(nil, _data), do: nil
  defp send!(pid, data), do: send(pid, data)

  defp start_timer(state) do
    %{idle_connection_timeout: delay} = config()
    delay = String.to_integer(delay)
    timer = Process.send_after(self(), :kill, delay)
    Map.put(state, :kill_timer, timer)
  end
end
