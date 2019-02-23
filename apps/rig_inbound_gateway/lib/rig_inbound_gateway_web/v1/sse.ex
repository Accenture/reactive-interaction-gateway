defmodule RigInboundGatewayWeb.V1.SSE do
  @moduledoc """
  Create a Server-Sent Events connection and wait for events/messages.
  """
  require Logger
  use Rig.Config, [:cors]

  use RigInboundGatewayWeb, :controller

  alias Result
  alias RIG.Subscriptions

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.Events
  alias RigInboundGateway.Subscriptions, as: RigInboundGatewaySubscriptions
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
    jwt_subscription_results =
      conn.query_params
      |> Map.get("jwt")
      |> Subscriptions.from_token()

    manual_subscription_results =
      conn.query_params
      |> Map.get("subscriptions", "[]")
      |> Subscriptions.from_json()

    all_subscriptions =
      (Result.filter_and_unwrap(jwt_subscription_results) ++
         Result.filter_and_unwrap(manual_subscription_results))
      |> Enum.uniq()

    RigInboundGatewaySubscriptions.check_and_forward_subscriptions(self(), all_subscriptions)

    # Schedule the first subscription refresh:
    Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)

    all_errors =
      jwt_subscription_results
      |> Result.filter_and_unwrap_err()
      |> Enum.concat(manual_subscription_results |> Result.filter_and_unwrap_err())

    conn
    |> send_chunk(Events.welcome_event(all_errors))
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
      {"cache-control", "no-cache"}
    ])
    |> send_chunked(_status = 200)
  end

  defp wait_for_events(conn, state \\ @initial_state, next_heartbeat \\ nil) do
    next_heartbeat =
      next_heartbeat || Timex.now() |> Timex.shift(milliseconds: @heartbeat_interval_ms)

    heartbeat_remaining_ms =
      next_heartbeat
      |> Timex.diff(Timex.now(), :milliseconds)
      |> max(0)

    receive do
      # Cloud Events are forwarded to the client:
      {:cloud_event, event} ->
        Logger.debug(fn -> inspect(event) end)

        conn
        # Forward the event:
        |> send_chunk(event)
        # Keep the connection open:
        |> wait_for_events(state, next_heartbeat)

      # (Re-)Set subscriptions for this connection:
      {:set_subscriptions, subscriptions} ->
        Logger.debug(fn -> inspect(subscriptions) end)
        # Trigger immediate refresh:
        EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)
        # Replace current subscriptions:
        state = Map.put(state, :subscriptions, subscriptions)

        conn
        # Notify the client:
        |> send_chunk(Events.subscriptions_set(subscriptions))
        # Keep the connection open:
        |> wait_for_events(state, next_heartbeat)

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
        |> wait_for_events(state)
    end
  end

  defp send_chunk(conn, :heartbeat) do
    send_chunk(conn, %ServerSentEvent{comments: ["heartbeat"]})
  end

  defp send_chunk(conn, %CloudEvent{json: json} = event) do
    event_id = CloudEvent.id!(event)
    event_type = CloudEvent.type!(event)
    server_sent_event = ServerSentEvent.new(json, id: event_id, type: event_type)
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
