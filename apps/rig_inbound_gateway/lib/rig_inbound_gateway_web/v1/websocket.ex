defmodule RigInboundGatewayWeb.V1.Websocket do
  @moduledoc """
  Cowboy WebSocket handler.

  As soon as Phoenix pulls in Cowboy 2 this will have to be rewritten using the
  :cowboy_websocket behaviour.
  """

  require Logger

  alias Jason

  alias Rig.EventFilter
  alias RigInboundGateway.Events
  alias RigInboundGateway.ImplicitSubscriptions.Jwt, as: JwtSubscriptions
  alias RigInboundGateway.Subscriptions

  @behaviour :cowboy_websocket_handler

  @heartbeat_interval_ms 15_000
  @subscription_refresh_interval_ms 60_000
  @initial_state %{
    subscriptions: []
  }

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  @impl :cowboy_websocket_handler
  def websocket_init(_type, req, _opts) do
    send(self(), :send_connection_token)

    token_param =
      Tuple.to_list(req)
      |> Enum.find(fn val -> is_binary(val) && String.starts_with?(val, "token=") end)

    if token_param do
      "token=" <> token = token_param
      jwt_subscriptions = JwtSubscriptions.infer_subscriptions([token])
      Subscriptions.check_and_forward_subscriptions(self(), jwt_subscriptions)
    end

    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)
    {:ok, req, @initial_state}
  end

  @impl :cowboy_websocket_handler
  def websocket_handle({:pong, _}, req, state) do
    # the client sends this as the response to the :ping heartbeat
    {:ok, req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_handle(in_frame, req, state) do
    Logger.debug(fn -> "[ws] unexpected input: #{inspect(in_frame)}" end)
    # This will close the connection:
    out_frame = {:close, 1003, "Unexpected input."}
    {:reply, out_frame, req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_info({:cloud_event, cloud_event}, req, state) do
    Logger.debug(fn -> inspect(cloud_event) end)
    # Forward the event:
    {:reply, frame(cloud_event), req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_info(:heartbeat, req, state) do
    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)
    {:reply, :ping, req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_info(:send_connection_token, req, state) do
    {:reply, frame(Events.welcome_event()), req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_info({:set_subscriptions, subscriptions}, req, state) do
    Logger.debug(fn -> inspect(subscriptions) end)
    # Trigger immediate refresh:
    EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)
    # Replace current subscriptions:
    state = Map.put(state, :subscriptions, subscriptions)
    # Notify the client:
    {:reply, frame(Events.subscriptions_set(subscriptions)), req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_info(:refresh_subscriptions, req, state) do
    EventFilter.refresh_subscriptions(state.subscriptions, [])
    Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)
    {:ok, req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_info({:session_killed, group}, req, state) do
    Logger.info("session killed: #{inspect(group)}")
    # This will close the connection:
    out_frame = {:close, 4000, "Session killed."}
    {:reply, out_frame, req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  defp frame(%{} = cloud_event) do
    {:text, Jason.encode!(cloud_event)}
  end
end
