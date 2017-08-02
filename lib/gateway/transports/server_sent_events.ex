defmodule Gateway.Transports.ServerSentEvents do
  @moduledoc """
  Phoenix-Transport implementation for server-sent events (SSE).

  A heartbeat is used to make sure the connection is still up. This way,
  broken connections are detected and the corresponding process can halt
  normally.

  Example:

    transport :sse, Gateway.Transport.Sse, heartbeat_timeout_ms: 5_000

  """
  require Logger
  alias Gateway.Transports.ServerSentEvents.Encoder

  defmodule ConnectionClosed do
    defexception message: "the connection has been closed unexpectedly"
  end

  ## Transport callbacks

  @behaviour Phoenix.Socket.Transport
  
  def default_config() do
    [
      heartbeat_timeout_ms: 10_000,
      serializer: Gateway.Transports.ServerSentEvents.Serializer,
      cowboy: Plug.Adapters.Cowboy.Handler,
    ]
  end

  ## Plug callbacks

  @behaviour Plug

  import Plug.Conn

  alias Phoenix.Socket.Transport
  alias Gateway.PresenceChannel

  @doc false
  def init(opts), do: opts

  @doc """
  Called by the Cowboy handler (defined in default_config by default).

  The function dispatches the request depending on the request method, etc.
  """
  def call(conn, {endpoint, handler, transport}) do
    {_, opts} = handler.__transport__(transport)
    conn
    |> fetch_query_params
    |> put_resp_header("access-control-allow-origin", "*")
    |> Plug.Conn.fetch_query_params
    |> Transport.transport_log(opts[:transport_log])
    |> Transport.force_ssl(handler, endpoint, opts)
    |> Transport.check_origin(handler, endpoint, opts, &status_json(&1, %{}))
    |> dispatch(endpoint, handler, transport, opts)
  end

  defp dispatch(%{halted: true} = conn, _, _, _, _) do
    conn
  end

  # Responds to pre-flight CORS requests with Allow-Origin-* headers.
  # We allow cross-origin requests as we always validate the Origin header.
  defp dispatch(%{method: "OPTIONS"} = conn, _, _, _, _) do
    headers = get_req_header(conn, "access-control-request-headers") |> Enum.join(", ")
    conn
    |> put_resp_header("access-control-allow-headers", headers)
    |> put_resp_header("access-control-allow-methods", "get, post, options")
    |> put_resp_header("access-control-max-age", "3600")
    |> send_resp(:ok, "")
  end

  # Sets up the actual SSE transport by connecting to the socket and channel,
  # forwarding incoming messages to the client.
  #
  # Expected parameters:
  #   user  .. the name of the user the channel belongs to
  #   token .. the JWT, which will be validated by the socket
  #
  defp dispatch(%{method: "GET", params: %{"user" => user, "token" => _token}} = conn,
                endpoint, handler, transport_name, opts) do
    topic = PresenceChannel.room_name(user)
    serializer = opts[:serializer]
    # Connect this Transport with the Socket configured for this route:
    case Transport.connect(endpoint, handler, transport_name, _transport = __MODULE__, serializer, conn.params) do
      {:ok, socket} ->
        # We're connected to the socket now, but we still need to join the
        # channel. To this end, we need to send a phx_join message to the
        # Channel Server using the Transport's dispatch function. If all goes
        # well (e.g., we're authorized to join), we automatically get
        # subscribed to the channel. Note that if we would just subscribe to
        # the respective PubSub topic directly, we'd skip the socket's auth
        # check as well as the channel implementation.
        join_msg = %Phoenix.Socket.Message{topic: topic, event: "phx_join", payload: %{}, ref: "1"}
        case Transport.dispatch(join_msg, _channels = %{}, socket) do
          {:joined, _channel_pid, reply_msg} ->
            Logger.debug("joined topic=#{topic} reply=#{inspect reply_msg}")
            conn
            |> set_up_chunked_transfer
            |> send_chunk(reply_msg |> serializer.encode! |> Encoder.format)
            |> receive_and_forward_loop(opts)
            |> send_chunk(:bye)
          {:error, reason, error_reply_msg} ->
            Logger.warn("failed to join topic=#{inspect topic}, reason=#{inspect reason}, msg=#{inspect error_reply_msg}")
            conn
            |> send_resp(:internal_server_error, error_reply_msg |> serializer.encode! |> Encoder.format)
        end
      :error ->
        Logger.debug("failed to connect with socket transport=#{inspect transport_name}/#{inspect __MODULE__} (opts=#{inspect opts}) handler=#{inspect handler} conn=#{inspect conn, pretty: true, limit: 30_000}")
        conn
        |> send_resp(:unauthorized, :unauthorized |> Encoder.format)
    end
  rescue
    ex in ConnectionClosed ->
      Logger.warn(inspect ex)
      # we should return _something_, so as to prevent a Plug.Conn.NotSentError:
      conn |> send_resp(:service_unavailable, :service_unavailable |> Encoder.format)
  end

  # All other requests should fail.
  defp dispatch(conn, _, _, _, _) do
    conn
    |> send_resp(:bad_request, "Bad request. Make sure you supply \"user\" and \"token\" parameters, and that you're authorized to access the user's channel.\n")
  end

  defp set_up_chunked_transfer(conn) do
    conn
    |> merge_resp_headers([
      {"content-type", "text/event-stream"},
      {"cache-control", "no-cache"},
      {"connection", "keep-alive"},
    ])
    |> send_chunked(_status = 200)
  end

  defp receive_and_forward_loop(conn, opts, next_heartbeat_timeout \\ nil)
  defp receive_and_forward_loop(conn, opts, nil) do
    receive_and_forward_loop(conn, opts, get_next_heartbeat_timeout(opts))
  end
  defp receive_and_forward_loop(conn, opts, next_heartbeat_timeout) do
    heartbeat_remaining_ms =
      next_heartbeat_timeout
      |> Timex.diff(Timex.now, :milliseconds)
      |> max(0)
    receive do
      %Phoenix.Socket.Message{} = msg ->
        Logger.debug("from channel: message=#{inspect msg}")
        conn
        |> send_chunk(msg |> Encoder.format)
        |> receive_and_forward_loop(opts, next_heartbeat_timeout)
    after
      heartbeat_remaining_ms ->
        # If the connection is down, the (second) heartbeat will trigger ConnectionClosed
        conn
        |> send_chunk(:heartbeat)
        |> receive_and_forward_loop(opts, get_next_heartbeat_timeout(opts))
    end
  end

  defp get_next_heartbeat_timeout(opts) do
    Timex.now |> Timex.shift(milliseconds: opts[:heartbeat_timeout_ms])
  end

  defp send_chunk(conn, the_chunk) when is_binary(the_chunk) do
    case chunk(conn, the_chunk) do
      {:ok, conn} -> conn
      {:error, :closed} ->
        raise ConnectionClosed
    end
  end
  defp send_chunk(conn, thing) do
    send_chunk(conn, Encoder.format(thing))
  end

  defp status_json(conn, data) do
    status = Plug.Conn.Status.code(conn.status || 200)
    data = Map.put(data, :status, status)
    conn
    |> put_status(200)
    |> Phoenix.Controller.json(data)
  end
end

