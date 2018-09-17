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
      {:cloud_event, cloud_event} ->
        Logger.debug(fn -> "[SSE] #{inspect(cloud_event)}" end)

        conn
        |> send_chunk(cloud_event)
        |> wait_for_events(state, next_heartbeat)

      {:register_subscription, subscription} ->
        Logger.debug(fn ->
          event_type = "eventType=#{inspect(subscription.event_type)}"
          constraints = "constraints=#{inspect(subscription.constraints)}"
          "[SSE] registered subscription: #{event_type} #{constraints}"
        end)

        send(self(), :refresh_subscriptions)
        state = update_in(state.subscriptions, &[subscription | &1])

        conn
        |> send_chunk(Events.subscription_create(subscription))
        |> wait_for_events(state, next_heartbeat)

      :refresh_subscriptions ->
        Logger.debug(fn ->
          "[SSE] refreshing #{length(state.subscriptions)} subscriptions"
        end)

        EventFilter.refresh_subscriptions(state.subscriptions)

        Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)
        wait_for_events(conn, state, next_heartbeat)

      {:session_killed, group} ->
        Logger.info("[SSE] session killed: #{inspect(group)}")
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
