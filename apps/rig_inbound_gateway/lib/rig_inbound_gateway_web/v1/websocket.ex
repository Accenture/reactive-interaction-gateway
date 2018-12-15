defmodule RigInboundGatewayWeb.V1.Websocket do
  @moduledoc """
  Cowboy WebSocket handler.

  As soon as Phoenix pulls in Cowboy 2 this will have to be rewritten using the
  :cowboy_websocket behaviour.
  """

  require Logger

  alias Jason

  alias Rig.EventFilter
  alias Rig.Subscription
  alias RigInboundGateway.AutomaticSubscriptions.Jwt, as: JwtSubscriptions
  alias RigInboundGateway.Events
  alias RigInboundGateway.Subscriptions

  @behaviour :cowboy_websocket

  @heartbeat_interval_ms 15_000
  @subscription_refresh_interval_ms 60_000

  # ---

  @impl :cowboy_websocket
  def init(req, :ok) do
    # TODO If token is given but invalid this crashes with
    # TODO {:badmatch, {:error, "Invalid signature"}}.
    # TODO Instead, logging should be moved from infer_subscriptions,
    # TODO with appropriate error handling.
    jwt_subscriptions =
      for {"jwt", token} <- :cowboy_req.parse_qs(req),
          candidates = JwtSubscriptions.infer_subscriptions([token]),
          candidate <- candidates,
          %Subscription{} = parsed = Subscription.new(candidate),
          do: parsed

    manual_subscriptions =
      for {"subscriptions", encoded} <- :cowboy_req.parse_qs(req),
          {:ok, candidates} = Jason.decode(encoded),
          candidate <- candidates,
          %Subscription{} = parsed = Subscription.new(candidate),
          do: parsed

    all_subscriptions = jwt_subscriptions ++ manual_subscriptions

    state = %{subscriptions: all_subscriptions}
    opts = %{idle_timeout: :infinity}

    {:cowboy_websocket, req, state, opts}
  end

  # ---

  @impl :cowboy_websocket
  def websocket_init(%{subscriptions: subscriptions} = state) do
    Subscriptions.check_and_forward_subscriptions(self(), subscriptions)

    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)
    {:reply, frame(Events.welcome_event()), state}
  end

  # ---

  @doc ~S"The client may send this as the response to the :ping heartbeat."
  @impl :cowboy_websocket
  def websocket_handle({:pong, _}, state), do: {:ok, state}
  @impl :cowboy_websocket
  def websocket_handle(:pong, state), do: {:ok, state}

  @impl :cowboy_websocket
  def websocket_handle(in_frame, state) do
    Logger.debug(fn -> "[ws] unexpected input: #{inspect(in_frame)}" end)
    # This will close the connection:
    out_frame = {:close, 1003, "Unexpected input."}
    {:reply, out_frame, state}
  end

  # ---

  @impl :cowboy_websocket
  def websocket_info({:cloud_event, cloud_event}, state) do
    Logger.debug(fn -> inspect(cloud_event) end)
    # Forward the event:
    {:reply, frame(cloud_event), state}
  end

  @impl :cowboy_websocket
  def websocket_info(:heartbeat, state) do
    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)
    {:reply, :ping, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:set_subscriptions, subscriptions}, state) do
    Logger.debug(fn -> inspect(subscriptions) end)
    # Trigger immediate refresh:
    EventFilter.refresh_subscriptions(subscriptions, state.subscriptions)
    # Replace current subscriptions:
    state = Map.put(state, :subscriptions, subscriptions)
    # Notify the client:
    {:reply, frame(Events.subscriptions_set(subscriptions)), state}
  end

  @impl :cowboy_websocket
  def websocket_info(:refresh_subscriptions, state) do
    EventFilter.refresh_subscriptions(state.subscriptions, [])
    Process.send_after(self(), :refresh_subscriptions, @subscription_refresh_interval_ms)
    {:ok, state}
  end

  @impl :cowboy_websocket
  def websocket_info({:session_killed, group}, state) do
    Logger.info("session killed: #{inspect(group)}")
    # This will close the connection:
    out_frame = {:close, 4000, "Session killed."}
    {:reply, out_frame, state}
  end

  # ---

  defp frame(%{} = cloud_event) do
    {:text, Jason.encode!(cloud_event)}
  end
end
