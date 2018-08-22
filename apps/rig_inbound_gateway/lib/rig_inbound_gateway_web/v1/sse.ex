defmodule RigInboundGatewayWeb.V1.SSE do
  @moduledoc """
  Create a Server-Sent Events connection and wait for events/messages.
  """
  require Logger

  use RigInboundGatewayWeb, :controller

  alias RigInboundGateway.Events
  alias Rig.CloudEvent
  alias ServerSentEvent

  defmodule ConnectionClosed do
    defexception message: "connection closed"
  end

  # As recommended at https://html.spec.whatwg.org/multipage/server-sent-events.html#authoring-notes
  @heartbeat_interval_ms 15_000

  @doc "Plug action to create a new SSE connection and wait for messages."
  def create_and_attach(conn, _params) do
    conn
    |> with_chunked_transfer()
    |> send_chunk(Events.welcome_event())
    |> wait_for_events()
  rescue
    ex in ConnectionClosed ->
      Logger.warn(inspect(ex))
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

  defp wait_for_events(conn, next_heartbeat_timeout \\ nil)

  defp wait_for_events(conn, nil) do
    next_heartbeat = Timex.now() |> Timex.shift(milliseconds: @heartbeat_interval_ms)
    wait_for_events(conn, next_heartbeat)
  end

  defp wait_for_events(conn, next_heartbeat) do
    heartbeat_remaining_ms =
      next_heartbeat
      |> Timex.diff(Timex.now(), :milliseconds)
      |> max(0)

    receive do
      {:rig_event, subscriber_group, cloud_event} ->
        Logger.debug(fn ->
          via = if is_nil(subscriber_group), do: "rig", else: inspect(subscriber_group)
          "[SSE] #{via}: #{inspect(cloud_event)}"
        end)

        conn
        |> send_chunk(cloud_event)
        |> wait_for_events(next_heartbeat)

      {:session_killed, group} ->
        Logger.info("[SSE] session killed: #{inspect(group)}")
        send_chunk(conn, %ServerSentEvent{comments: ["Session killed."]})
    after
      heartbeat_remaining_ms ->
        # If the connection is down, the (second) heartbeat will trigger ConnectionClosed
        conn
        |> send_chunk(:heartbeat)
        |> wait_for_events(nil)
    end
  end

  defp send_chunk(conn, :heartbeat) do
    send_chunk(conn, %ServerSentEvent{comments: ["heartbeat"]})
  end

  defp send_chunk(conn, %CloudEvent{} = cloud_event) do
    server_sent_event =
      cloud_event
      |> CloudEvent.serialize()
      |> ServerSentEvent.new(id: cloud_event.event_id, type: cloud_event.event_type)

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
