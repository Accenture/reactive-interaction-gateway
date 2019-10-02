defmodule RigInboundGatewayWeb.V1.Websocket do
  @moduledoc """
  Cowboy WebSocket handler.
  """

  require Logger

  alias Jason

  alias Result

  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.Events
  alias RigInboundGatewayWeb.ConnectionInit

  @behaviour :cowboy_websocket

  @heartbeat_interval_ms 15_000
  @subscription_refresh_interval_ms 60_000

  # ---

  @impl :cowboy_websocket
  def init(req, :ok) do
    query_params = req |> :cowboy_req.parse_qs() |> Enum.into(%{})

    # The initialization is done in the websocket handler, which is a different process.

    # Upgrade the connection to WebSocket protocol:
    state = %{query_params: query_params}
    opts = %{idle_timeout: :infinity}
    {:cowboy_websocket, req, state, opts}
  end

  # ---

  @impl :cowboy_websocket
  def websocket_init(%{query_params: query_params}) do
    jwt = query_params["jwt"]
    connection_token = query_params["connection_token"]

    auth_info =
      case jwt do
        jwt when byte_size(jwt) > 0 ->
          %{auth_header: "Bearer #{jwt}", auth_tokens: [{"bearer", jwt}]}

        _ ->
          nil
      end

    case ConnectionInit.subscriptions_query_param_to_body(query_params) do
      {:ok, encoded_body_or_nil} ->
        request = %{
          auth_info: auth_info,
          query_params: "",
          content_type: "application/json; charset=utf-8",
          body: encoded_body_or_nil,
          connection_token: connection_token
        }

        do_init(request)

      {:error, reason} ->
        {:reply, closing_frame(reason), :no_state}
    end
  end

  # ---

  def do_init(request) do
    on_success = fn subscriptions, vconnection_pid ->
      # Say "hi", enter the loop and wait for cloud events to forward to the client:
      state = %{subscriptions: subscriptions}
      {:reply, frame(Events.welcome_event(vconnection_pid)), state, :hibernate}
    end

    on_error = fn _reason ->
      # WebSocket close frames may include a payload to indicate the error, but we found
      # that error message must be really short; if it isn't, the `{:close, :normal,
      # payload}` is silently converted to `{:close, :abnormal, nil}`. Since there is no
      # limit mentioned in the spec (RFC-6455), we opt for consistent responses,
      # omitting the detailed error.
      reason = "Bad request."
      # This will close the connection:
      {:reply, closing_frame(reason), :no_state}
    end

     # TODO: Handle existing connection token in connection_init; use GenServer.call with a timeout of 500ms to check if VConnection is alive
    ConnectionInit.set_up(
      "WS",
      request,
      on_success,
      on_error,
      @heartbeat_interval_ms,
      @subscription_refresh_interval_ms
    )
  end

  # ---

  @doc ~S"The client may send this as the response to the :ping heartbeat."
  @impl :cowboy_websocket
  def websocket_handle({:pong, _app_data}, state), do: {:ok, state, :hibernate}
  @impl :cowboy_websocket
  def websocket_handle(:pong, state), do: {:ok, state, :hibernate}

  @doc ~S"Allow the client to send :ping messages to test connectivity."
  @impl :cowboy_websocket
  def websocket_handle({:ping, app_data}, state), do: {:reply, {:pong, app_data}, :hibernate}

  @impl :cowboy_websocket
  def websocket_handle(in_frame, state) do
    Logger.debug(fn -> "Unexpected WebSocket input: #{inspect(in_frame)}" end)
    # This will close the connection:
    {:reply, closing_frame("This WebSocket endpoint cannot be used for two-way communication."),
     state}
  end

  # ---

  @impl :cowboy_websocket
  def websocket_info({:forward, :heartbeat}, state) do
    # Ping the client to keep the connection alive:
    {:reply, :ping, state, :hibernate}
  end

  @impl :cowboy_websocket
  def websocket_info({:forward, data}, state) do
    {:reply, frame(data), state, :hibernate}
  end

  @impl :cowboy_websocket
  def websocket_info({:session_killed, session_id}, state) do
    Logger.info("Session killed: #{inspect(session_id)} - terminating WS/#{inspect(self())}..")
    # This will close the connection:
    {:reply, closing_frame("Session killed."), state}
  end

  @impl :cowboy_websocket
  def websocket_info(:close, state) do
    # TODO: Test
    {:reply, closing_frame("Connection closed."), state}
  end

  @impl :cowboy_loop
  def websocket_info({:DOWN, _ref, :process, pid, _}, req, state) do
    send self(), :close
    {:ok, state}
  end

  # ---

  @impl :cowboy_websocket
  def terminate(reason, _req, _state) do
    Logger.debug(fn ->
      pid = inspect(self())
      reason = "reason=" <> inspect(reason)
      "Closing WebSocket connection (#{pid}, #{reason})"
    end)

    :ok
  end

  # ---

  defp frame(%CloudEvent{json: json}) do
    {:text, json}
  end

  # ---

  defp closing_frame(reason) do
    # Sending this will close the connection:
    {
      :close,
      # "Normal Closure":
      1_000,
      reason
    }
  end
end
