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

  @token_query_param "auth_token"
  @usage_text """
  Please make sure that the HTTP Authorization header contains the JWT as the bearer token.

  Usage:

    GET /socket/sse
    Authorization: Bearer eyJhbGc...
  """

  defmodule ConnectionClosed do
    defexception message: "connection closed"
  end

  defp validate_config!(nil), do: validate_config!([])

  defp validate_config!(config) do
    {user_target_mod, user_target_fun} = Keyword.fetch!(config, :user_channel_name_mf)

    %{
      user_channel_name: fn user -> apply(user_target_mod, user_target_fun, [user]) end
    }
  end

  ## Transport callbacks

  @behaviour Phoenix.Socket.Transport

  def default_config do
    [
      heartbeat_timeout_ms: 10_000,
      serializer: RigInboundGateway.Transports.ServerSentEvents.Serializer,
      cowboy: Plug.Adapters.Cowboy.Handler
    ]
  end

  ## Plug callbacks

  @behaviour Plug

  import Plug.Conn

  alias Phoenix.Socket.Transport
  alias RigAuth.Jwt.Utils, as: Jwt

  @doc false
  def init(opts), do: opts

  @doc """
  Called by the Cowboy handler (defined in default_config by default).

  The function dispatches the request depending on the request method, etc.
  """
  def call(conn, {endpoint, handler, transport}) do
    {_, opts} = handler.__transport__(transport)

    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> Plug.Conn.fetch_query_params()
    |> Transport.transport_log(opts[:transport_log])
    |> Transport.force_ssl(handler, endpoint, opts)
    |> Transport.check_origin(handler, endpoint, opts, &status_json(&1, %{}))
    |> dispatch(endpoint, handler, transport, opts)
  end

  defp dispatch(conn, endpoint, handler, transport, opts) do
    case conn do
      %{halted: true} ->
        # The connection hasn't survived the previous checks..
        conn

      %{method: "OPTIONS"} ->
        # Handle pre-flight CORS requests:
        handle_options_request(conn)

      %{method: "GET"} ->
        # Have the connection subscribed to the user topic:
        attach_to_user_socket(conn, endpoint, handler, transport, opts)

      _ ->
        # Fail all other requests:
        send_resp(conn, :bad_request, error_response_text("Bad request."))
    end
  end

  # Responds to pre-flight CORS requests with Allow-Origin-* headers.
  # We allow cross-origin requests as we always validate the Origin header.
  defp handle_options_request(conn) do
    headers = get_req_header(conn, "access-control-request-headers") |> Enum.join(", ")

    conn
    |> put_resp_header("access-control-allow-headers", headers)
    |> put_resp_header("access-control-allow-methods", "get, post, options")
    |> put_resp_header("access-control-max-age", "3600")
    |> send_resp(:ok, "")
  end

  defp attach_to_user_socket(
         conn,
         endpoint,
         handler,
         transport_name,
         opts
       ) do
    conf = config()
    serializer = opts[:serializer]

    token = get_token(conn)
    conn = Map.put(conn, :params, Map.put(conn.params, "token", token))

    with {:ok, user_id} <- user_id_from_token(token),
         user_channel_name <- conf.user_channel_name.(user_id),
         {:ok, socket} <- open_socket(endpoint, handler, transport_name, serializer, conn.params),
         {:ok, _reply} <- subscribe_to_channel(socket, user_channel_name) do
      conn
      |> set_up_chunked_transfer()
      |> send_chunk(:hello)
      |> attach_to_channel(opts)
      # TODO publish leave messages to topic
      |> send_chunk(:bye)
    else
      {:error, :socket_connection_denied} ->
        send_resp(conn, :unauthorized, :unauthorized |> Encoder.format())

      {:error, :no_token} ->
        send_resp(conn, :bad_request, "No bearer token found.")

      {:error, :invalid_token} ->
        send_resp(conn, :bad_request, "Bearer token is not valid.")

      err ->
        Logger.warn(fn ->
          "Channel subscription failed: #{inspect(err)}"
        end)

        send_resp(conn, :internal_server_error, "Internal server error.")
    end
  rescue
    ex in ConnectionClosed ->
      Logger.warn(inspect(ex))
      # we should return _something_, so as to prevent a Plug.Conn.NotSentError:
      conn |> send_resp(:service_unavailable, :service_unavailable |> Encoder.format())
  end

  @type user_id_error :: {:error, :no_token | :invalid_token | String.t()}
  @spec user_id_from_token(String.t()) :: {:ok, String.t()} | user_id_error
  defp user_id_from_token(token) do
    with true <- not is_nil(token) || {:error, :no_token},
         true <- Jwt.valid?(token) || {:error, :invalid_token},
         {:ok, %{"user" => user_id}} <- Jwt.decode(token) do
      {:ok, user_id}
    end
  end

  @spec get_token(conn :: %Plug.Conn{}) :: String.t() | nil
  defp get_token(conn) do
    # Putting the token into the query overrides what's in the header:
    case token_from_query(conn) do
      nil ->
        # No token in the query, return what's in the header (might be nil):
        token_from_header(conn)

      query_token ->
        # There is a token! If there is an authZ header too, they need to match:
        header_token = token_from_header(conn)
        ensure_no_or_matching_header_token(query_token, header_token)
    end
  end

  defp ensure_no_or_matching_header_token(query_token, nil), do: query_token

  defp ensure_no_or_matching_header_token(query_token, header_token) do
    # If they don't match, we ignore the tokens altogether:
    if query_token == header_token, do: query_token, else: nil
  end

  @spec token_from_header(conn :: %Plug.Conn{}) :: String.t() | nil
  defp token_from_header(conn) do
    case get_req_header(conn, "authorization") do
      [value | _] -> token_from_bearer(value)
      _ -> nil
    end
  end

  # This is the (OAuth) standard:
  defp token_from_bearer("Bearer " <> token), do: token
  # This is not, but we accept it anyway:
  defp token_from_bearer("bearer " <> token), do: token
  defp token_from_bearer(_), do: nil

  @spec token_from_query(conn :: %Plug.Conn{}) :: String.t() | nil
  defp token_from_query(conn) do
    Map.get(conn.params, @token_query_param, nil)
  end

  defp open_socket(endpoint, handler, transport_name, serializer, params) do
    case Transport.connect(
           endpoint,
           handler,
           transport_name,
           _transport = __MODULE__,
           serializer,
           params
         ) do
      {:ok, socket} -> {:ok, socket}
      _ -> {:error, :socket_connection_denied}
    end
  end

  defp set_up_chunked_transfer(conn) do
    conn
    |> merge_resp_headers([
      {"content-type", "text/event-stream"},
      {"cache-control", "no-cache"},
      {"connection", "keep-alive"}
    ])
    |> send_chunked(_status = 200)
  end

  defp subscribe_to_channel(socket, channel) do
    # Special message for joining the channel:
    join_msg = %Phoenix.Socket.Message{topic: channel, event: "phx_join", payload: %{}}
    # If successful, we get subscribed to the channel. Note that if we
    # would just subscribe to the respective PubSub topic directly, we'd
    # skip the socket's auth check as well as the channel implementation.
    case Transport.dispatch(join_msg, _channels = %{}, socket) do
      {:joined, _channel_pid, reply_msg} ->
        {:ok, reply_msg}

      {:error, reason, error_reply_msg} ->
        {:error, :channel_subscription_failed, reason, error_reply_msg}
    end
  end

  defp attach_to_channel(conn, opts, next_heartbeat_timeout \\ nil)

  defp attach_to_channel(conn, opts, nil) do
    attach_to_channel(conn, opts, get_next_heartbeat_timeout(opts))
  end

  defp attach_to_channel(conn, opts, next_heartbeat_timeout) do
    heartbeat_remaining_ms =
      next_heartbeat_timeout
      |> Timex.diff(Timex.now(), :milliseconds)
      |> max(0)

    receive do
      {:cowboy_req, _} ->
        # Cowboy events are ignored.
        attach_to_channel(conn, opts, next_heartbeat_timeout)

      {:plug_conn, _} ->
        # Plug events are ignored.
        attach_to_channel(conn, opts, next_heartbeat_timeout)

      %Phoenix.Socket.Message{event: "presence_state"} ->
        # Phoenix events are ignored.
        attach_to_channel(conn, opts, next_heartbeat_timeout)

      %Phoenix.Socket.Message{event: "presence_diff"} ->
        # Phoenix events are ignored.
        attach_to_channel(conn, opts, next_heartbeat_timeout)

      %Phoenix.Socket.Message{event: "phx_reply"} ->
        # Phoenix events are ignored.
        attach_to_channel(conn, opts, next_heartbeat_timeout)

      %Phoenix.Socket.Message{} = msg ->
        Logger.debug(fn -> "from channel: message=#{inspect(msg)}" end)

        conn
        |> send_chunk(msg |> Encoder.format())
        |> attach_to_channel(opts, next_heartbeat_timeout)

      unexpected_msg ->
        Logger.warn(fn -> "Unexpectedly received: #{inspect(unexpected_msg)}" end)
        attach_to_channel(conn, opts, next_heartbeat_timeout)
    after
      heartbeat_remaining_ms ->
        # If the connection is down, the (second) heartbeat will trigger ConnectionClosed
        conn
        |> send_chunk(:heartbeat)
        |> attach_to_channel(opts, get_next_heartbeat_timeout(opts))
    end
  end

  defp get_next_heartbeat_timeout(opts) do
    Timex.now() |> Timex.shift(milliseconds: opts[:heartbeat_timeout_ms])
  end

  defp send_chunk(conn, the_chunk) when is_binary(the_chunk) do
    case chunk(conn, the_chunk) do
      {:ok, conn} ->
        conn

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

  defp error_response_text(reason) do
    "\n#{reason}\n\n#{@usage_text}\n\n"
  end
end
