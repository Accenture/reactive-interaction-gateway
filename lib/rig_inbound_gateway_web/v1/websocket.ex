defmodule RigInboundGatewayWeb.V1.Websocket do
  @moduledoc """
  Cowboy WebSocket handler.
  """

  require Logger

  alias Jason

  alias Result

  alias RIG.AuthorizationCheck.Request
  alias Rig.EventFilter
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

    auth_info =
      case jwt do
        jwt when byte_size(jwt) > 0 ->
          %{auth_header: "Bearer #{jwt}", auth_tokens: [{"bearer", jwt}]}

        _ ->
          nil
      end

    case ConnectionInit.subscriptions_query_param_to_body(query_params) do
      {:ok, encoded_body_or_nil} ->
        request = %Request{
          auth_info: auth_info,
          query_params: "",
          content_type: "application/json; charset=utf-8",
          body: encoded_body_or_nil
        }

        do_init(request)

      {:error, reason} ->
        {:reply, closing_frame(reason), :no_state}
    end
  end

  # ---

  def do_init(request) do
    on_success = fn subscriptions ->
      # Say "hi", enter the loop and wait for cloud events to forward to the client:
      state = %{subscriptions: subscriptions}
      {:reply, frame(Events.welcome_event()), state, :hibernate}
    end

    on_error = fn reason ->
      Logger.warn(fn -> "websocket error: #{inspect(reason)}" end)
      # WebSocket close frames may include a payload to indicate the error, but we found
      # that error message must be really short; if it isn't, the `{:close, :normal,
      # payload}` is silently converted to `{:close, :abnormal, nil}`. Since there is no
      # limit mentioned in the spec (RFC-6455), we opt for consistent responses,
      # omitting the detailed error.
      reply =
        case reason do
          {403, _} -> "Not authorized."
          {code, _} -> "#{code}: Bad request."
          _ -> "Bad request."
        end

      # This will close the connection:
      {:reply, closing_frame(reply), :no_state}
    end

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

  # The client may send this as the response to the :ping heartbeat.
  @impl :cowboy_websocket
  def websocket_handle({:pong, _app_data}, state), do: {:ok, state, :hibernate}
  @impl :cowboy_websocket
  def websocket_handle(:pong, state), do: {:ok, state, :hibernate}

  # Allow the client to send :ping messages to test connectivity.
  @impl :cowboy_websocket
  def websocket_handle({:ping, app_data}, _state), do: {:reply, {:pong, app_data}, :hibernate}

  @impl :cowboy_websocket
  def websocket_handle(in_frame, state) do
    Logger.debug(fn -> "Unexpected WebSocket input: #{inspect(in_frame)}" end)
    # This will close the connection:
    {:reply, closing_frame("This WebSocket endpoint cannot be used for two-way communication."),
     state}
  end

  # ---

  @impl :cowboy_websocket
  def websocket_info(:heartbeat, state) do
    # Schedule the next heartbeat:
    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)
    # Ping the client to keep the connection alive:
    {:reply, :ping, state, :hibernate}
  end

  @impl :cowboy_websocket
  def websocket_info(event, state) when is_struct(event) do
    Logger.debug(fn -> "event: " <> inspect(event) end)
    # Forward the event to the client:
    {:reply, frame(event), state, :hibernate}
  end

  @impl :cowboy_websocket
  def websocket_info({:set_subscriptions, subscriptions}, state) do
    Logger.debug(fn -> "subscriptions: " <> inspect(subscriptions) end)
    # Trigger immediate refresh:
    EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)
    # Replace current subscriptions:
    state = Map.put(state, :subscriptions, subscriptions)
    # Notify the client:
    {:reply, frame(Events.subscriptions_set(subscriptions)), state, :hibernate}
  end

  @impl :cowboy_websocket
  def websocket_info(:refresh_subscriptions, state) do
    EventFilter.refresh_subscriptions(state.subscriptions, [])
    Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:session_killed, session_id}, state) do
    Logger.info("Session killed: #{inspect(session_id)} - terminating WS/#{inspect(self())}..")
    # This will close the connection:
    {:reply, closing_frame("Session killed."), state}
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

  defp frame(event) do
    {:text, Cloudevents.to_json(event)}
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
