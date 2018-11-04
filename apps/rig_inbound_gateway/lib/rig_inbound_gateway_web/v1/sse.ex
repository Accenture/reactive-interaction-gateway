defmodule RigInboundGatewayWeb.V1.SSE do
  @moduledoc """
  Create a Server-Sent Events connection and wait for events/messages.
  """
  require Logger
  use Rig.Config, [:cors]

  use RigInboundGatewayWeb, :controller

  alias Rig.EventFilter
  alias RigInboundGateway.Events
  alias ServerSentEvent

  defmodule ConnectionClosed do
    defexception message: "connection closed"
  end

  # As recommended at https://html.spec.whatwg.org/multipage/server-sent-events.html#authoring-notes
  @heartbeat_interval_ms 15_000
  @subscription_refresh_interval_ms 60_000
  @initial_state %{
    subscriptions: []
  }

  @doc "Plug action to create a new SSE connection and wait for messages."
  def create_and_attach(%{method: "GET"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> with_chunked_transfer()
    |> do_create_and_attach()
  end

  defp do_create_and_attach(conn) do
    conn
    |> send_chunk(Events.welcome_event())
    |> wait_for_events()
  rescue
    ex in ConnectionClosed ->
      Logger.warn(inspect(ex))
      conn
  end

  defp with_allow_origin(conn) do
    %{cors: origins} = config()
    put_resp_header(conn, "access-control-allow-origin", origins)
  end

  defp with_chunked_transfer(conn) do
    conn
    |> merge_resp_headers([
      {"content-type", "text/event-stream"},
      {"cache-control", "no-cache"},
      {"connection", "keep-alive"}
    ])
    |> send_chunked(_status = 200)
  end

  defp wait_for_events(conn, state \\ @initial_state, next_heartbeat_timeout \\ nil)

  defp wait_for_events(conn, state, nil) do
    next_heartbeat = Timex.now() |> Timex.shift(milliseconds: @heartbeat_interval_ms)
    wait_for_events(conn, state, next_heartbeat)
  end

  defp wait_for_events(conn, state, next_heartbeat) do
    heartbeat_remaining_ms =
      next_heartbeat
      |> Timex.diff(Timex.now(), :milliseconds)
      |> max(0)

    receive do
      # Cloud Events are forwarded to the client:
      {:cloud_event, cloud_event} ->
        Logger.debug(fn -> inspect(cloud_event) end)
        # Forward the event:
        send_chunk(conn, cloud_event)
        # Keep the connection open:
        wait_for_events(conn, state, next_heartbeat)

      # (Re-)Set subscriptions for this connection:
      {:set_subscriptions, subscriptions} ->
        Logger.debug(fn -> inspect(subscriptions) end)
        # Trigger immediate refresh:
        EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)
        # Replace current subscriptions:
        state = Map.put(state, :subscriptions, subscriptions)
        # Notify the client:
        send_chunk(conn, Events.subscriptions_set(subscriptions))
        # Keep the connection open:
        wait_for_events(conn, state, next_heartbeat)

      # Subscriptions need to be refreshed periodically:
      :refresh_subscriptions ->
        EventFilter.refresh_subscriptions(state.subscriptions, [])
        Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)
        # Keep the connection open:
        wait_for_events(conn, state, next_heartbeat)

      # In case the connection belongs to a session and that session is killed,
      # exit the loop and close the connection:
      {:session_killed, group} ->
        Logger.info("session killed: #{inspect(group)}")
        send_chunk(conn, %ServerSentEvent{comments: ["Session killed."]})
    after
      heartbeat_remaining_ms ->
        # If the connection is down, the (second) heartbeat will trigger ConnectionClosed
        conn
        |> send_chunk(:heartbeat)
        |> wait_for_events(state, nil)
    end
  end

  defp send_chunk(conn, :heartbeat) do
    send_chunk(conn, %ServerSentEvent{comments: ["heartbeat"]})
  end

  defp send_chunk(conn, %{"eventID" => event_id, "eventType" => event_type} = cloud_event) do
    server_sent_event =
      cloud_event
      |> Jason.encode!()
      |> ServerSentEvent.new(id: event_id, type: event_type)

    send_chunk(conn, server_sent_event)
  end

  defp send_chunk(conn, %ServerSentEvent{} = event) do
    send_chunk(conn, ServerSentEvent.serialize(event))
  end

  defp send_chunk(conn, chunk) when is_binary(chunk) do
    case Plug.Conn.chunk(conn, chunk) do
      {:ok, conn} -> conn
      {:error, :closed} -> raise ConnectionClosed
    end
  end
end
