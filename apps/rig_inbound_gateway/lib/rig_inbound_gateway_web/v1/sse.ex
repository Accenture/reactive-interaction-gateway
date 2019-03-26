defmodule RigInboundGatewayWeb.V1.SSE do
  @moduledoc """
  Cowboy WebSocket handler.

  As soon as Phoenix pulls in Cowboy 2 this will have to be rewritten using the
  :cowboy_websocket behaviour.
  """

  require Logger

  alias Jason
  alias ServerSentEvent

  alias Result

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.Events
  alias RigInboundGatewayWeb.ConnectionInit

  @behaviour :cowboy_loop

  @heartbeat_interval_ms 15_000
  @subscription_refresh_interval_ms 60_000

  # ---

  @impl :cowboy_loop
  def init(req, :ok = state) do
    query_params = req |> :cowboy_req.parse_qs() |> Enum.into(%{})

    on_success = fn subscriptions ->
      # Tell the client the request is good and the response is chunked:
      req = :cowboy_req.stream_reply(200, req)

      # Say hello to the client:
      Events.welcome_event()
      |> serialize()
      |> :cowboy_req.stream_body(:nofin, req)

      # Enter the loop and wait for cloud events to forward to the client:
      state = %{subscriptions: subscriptions}
      {:cowboy_loop, req, state, :hibernate}
    end

    on_error = fn reason ->
      req = :cowboy_req.reply(400, %{}, reason, req)
      {:stop, req, state}
    end

    ConnectionInit.set_up(
      "SSE",
      query_params,
      on_success,
      on_error,
      @heartbeat_interval_ms,
      @subscription_refresh_interval_ms
    )
  end

  # ---

  @impl :cowboy_loop
  def info(:heartbeat, req, state) do
    # We send a heartbeat now:
    :heartbeat
    |> serialize()
    |> :cowboy_req.stream_body(:nofin, req)

    # And schedule the next one:
    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)

    {:ok, req, state, :hibernate}
  end

  @impl :cowboy_loop
  def info(%CloudEvent{} = event, req, state) do
    Logger.debug(fn -> inspect(event) end)

    # Forward the event to the client:
    event
    |> serialize()
    |> :cowboy_req.stream_body(:nofin, req)

    {:ok, req, state, :hibernate}
  end

  @impl :cowboy_loop
  def info({:set_subscriptions, subscriptions}, req, state) do
    Logger.debug(fn -> inspect(subscriptions) end)

    # Trigger immediate refresh:
    EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)

    # Replace current subscriptions:
    state = Map.put(state, :subscriptions, subscriptions)

    # Notify the client:
    Events.subscriptions_set(subscriptions)
    |> serialize()
    |> :cowboy_req.stream_body(:nofin, req)

    {:ok, req, state, :hibernate}
  end

  @impl :cowboy_loop
  def info(:refresh_subscriptions, req, state) do
    EventFilter.refresh_subscriptions(state.subscriptions, [])
    Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)
    {:ok, req, state, :hibernate}
  end

  @impl :cowboy_loop
  def info({:session_killed, group}, req, state) do
    Logger.info("session killed: #{inspect(group)}")

    # We tell the client:
    :session_killed
    |> serialize()
    |> :cowboy_req.stream_body(:nofin, req)

    # And close the connection:
    {:stop, req, state}
  end

  # ---

  defp serialize(:heartbeat) do
    %ServerSentEvent{comments: ["heartbeat"]}
    |> ServerSentEvent.serialize()
  end

  defp serialize(:session_killed) do
    %ServerSentEvent{comments: ["Session killed."]}
    |> ServerSentEvent.serialize()
  end

  defp serialize(%CloudEvent{json: json} = event) do
    event_id = CloudEvent.id!(event)
    event_type = CloudEvent.type!(event)

    json
    |> ServerSentEvent.new(id: event_id, type: event_type)
    |> ServerSentEvent.serialize()
  end
end
