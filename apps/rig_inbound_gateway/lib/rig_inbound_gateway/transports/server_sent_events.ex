defmodule RigInboundGateway.Transports.ServerSentEvents do
  @moduledoc """
  Phoenix-Transport implementation for server-sent events (SSE).

  A heartbeat is used to make sure the connection is still up. This way,
  broken connections are detected and the corresponding process can halt
  normally.

  Example:

    transport :sse, RigInboundGateway.Transport.Sse, heartbeat_timeout_ms: 5_000

  """
  use Rig.Config, :custom_validation
  require Logger

  alias RigInboundGateway.Transports.ServerSentEvents.Encoder

  defmodule ConnectionClosed do
    defexception message: "connection closed"
  end

  defp validate_config!(nil), do: validate_config!([])
  defp validate_config!(config) do
    {user_target_mod, user_target_fun} = Keyword.fetch!(config, :user_channel_name_mf)
    {role_target_mod, role_target_fun} = Keyword.fetch!(config, :role_channel_name_mf)
    %{
      user_channel_name: fn user -> apply(user_target_mod, user_target_fun, [user]) end,
      role_channel_name: fn role -> apply(role_target_mod, role_target_fun, [role]) end,
    }
  end

  ## Transport callbacks

  @behaviour Phoenix.Socket.Transport

  def default_config do
    [
      heartbeat_timeout_ms: 10_000,
      serializer: RigInboundGateway.Transports.ServerSentEvents.Serializer,
      cowboy: Plug.Adapters.Cowboy.Handler,
    ]
  end

  ## Plug callbacks

  @behaviour Plug

  import Plug.Conn

  alias Phoenix.Socket.Transport

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
  #   token .. (required) the JWT, which will be validated by the socket.
  #   users .. if given, messages that target the given users are forwarded to the client.
  #   roles .. if given, messages that target the given roles are forwarded to the client.
  #
  defp dispatch(%{method: "GET", params: %{"token" => _token} = params} = conn,
                endpoint, handler, transport_name, opts) do
    conf = config()
    user_channels = Map.get(params, "users", []) |> Enum.map(conf.user_channel_name)
    role_channels = Map.get(params, "roles", []) |> Enum.map(conf.role_channel_name)
    channels = Enum.uniq(user_channels ++ role_channels)
    case channels do
      [] ->
        conn
        |> send_resp(:not_found, "no channels selected\n")
      _ ->
        conn
        |> connect_subscribe_listen_forward(endpoint, handler, transport_name, channels, opts)
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
    |> send_resp(:bad_request,
                 """
                 Bad request. Make sure you supply the right parameters, and that you're authorized to access the user's channel.

                 Example: ?users[]=some.user&users[]=other.user&roles[]=support&token=my-jwt
                 """)
  end

  defp connect_subscribe_listen_forward(conn, endpoint, handler, transport_name,
                                        channels, opts) when length(channels) > 0 do
    case Transport.connect(endpoint, handler,
                           transport_name, _transport = __MODULE__,
                           opts[:serializer], conn.params) do
      {:ok, socket} ->
        # We're connected to the socket now, but we still need to join the channel.
        conn = conn |> set_up_chunked_transfer
        ok? =
          socket
          |> subscribe_to_channels(channels)
          |> Enum.map(fn(reply) -> handle_dispatch_reply(reply, conn, opts[:serializer]) end)
          |> Enum.all?(&(&1 == :ok))
        if ok? do
          conn |> receive_and_forward_loop(opts)
        else
          conn
        end
        |> send_chunk(:bye)
      :error ->
        Logger.debug(fn -> "failed to connect with socket transport=#{inspect transport_name}/#{inspect __MODULE__} (opts=#{inspect opts}) handler=#{inspect handler} conn=#{inspect conn, pretty: true, limit: 30_000}" end)
        conn
        |> send_resp(:unauthorized, :unauthorized |> Encoder.format)
    end
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

  defp subscribe_to_channels(socket, channels) do
    Enum.map(channels, fn
      (channel) ->
        # Special message for joining the channel:
        join_msg = %Phoenix.Socket.Message{topic: channel, event: "phx_join", payload: %{}}
        # If successful, we get subscribed to the channel. Note that if we
        # would just subscribe to the respective PubSub topic directly, we'd
        # skip the socket's auth check as well as the channel implementation.
        Transport.dispatch(join_msg, _channels = %{}, socket)
      end)
  end

  defp handle_dispatch_reply({:joined, _channel_pid, reply_msg}, conn, serializer) do
    Logger.debug(fn -> ":joined msg=#{inspect reply_msg}" end)
    conn
    |> send_chunk(reply_msg |> serializer.encode! |> Encoder.format)
    :ok
  end
  defp handle_dispatch_reply({:error, reason, error_reply_msg}, conn, serializer) do
    Logger.debug(fn -> ":error reason=#{inspect reason} msg=#{inspect error_reply_msg}" end)
    conn
    |> send_resp(:internal_server_error, error_reply_msg |> serializer.encode! |> Encoder.format)
    :error
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
        Logger.debug(fn -> "from channel: message=#{inspect msg}" end)
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
