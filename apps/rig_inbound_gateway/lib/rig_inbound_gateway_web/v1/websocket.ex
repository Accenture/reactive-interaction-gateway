defmodule RigInboundGatewayWeb.V1.Websocket do
  @moduledoc """
  Cowboy WebSocket handler.

  As soon as Phoenix pulls in Cowboy 2 this will have to be rewritten using the
  :cowboy_websocket behaviour.
  """

  require Logger

  alias Jason

  alias Result
  alias RIG.Subscriptions

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.Events
  alias RigInboundGateway.Subscriptions, as: RigInboundGatewaySubscriptions

  @behaviour :cowboy_websocket

  @heartbeat_interval_ms 15_000
  @subscription_refresh_interval_ms 60_000

  # ---

  @impl :cowboy_websocket
  def init(req, :ok) do
    query_params = req |> :cowboy_req.parse_qs() |> Enum.into(%{})

    jwt_subscription_results =
      query_params
      |> Map.get("jwt")
      |> Subscriptions.from_token()

    manual_subscription_results =
      query_params
      |> Map.get("subscriptions", "[]")
      |> Subscriptions.from_json()

    all_subscriptions =
      (Result.filter_and_unwrap(jwt_subscription_results) ++
         Result.filter_and_unwrap(manual_subscription_results))
      |> Enum.uniq()

    all_errors =
      jwt_subscription_results
      |> Result.filter_and_unwrap_err()
      |> Enum.concat(manual_subscription_results |> Result.filter_and_unwrap_err())

    state = %{subscriptions: all_subscriptions, errors: all_errors}
    opts = %{idle_timeout: :infinity}

    {:cowboy_websocket, req, state, opts}
  end

  # ---

  @impl :cowboy_websocket
  def websocket_init(%{subscriptions: subscriptions, errors: errors} = state) do
    RigInboundGatewaySubscriptions.check_and_forward_subscriptions(self(), subscriptions)

    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)
    {:reply, frame(Events.welcome_event(errors)), %{state | errors: []}}
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
  def websocket_info({:cloud_event, event}, state) do
    Logger.debug(fn -> inspect(event) end)
    # Forward the event:
    {:reply, frame(event), state}
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

  defp frame(%CloudEvent{json: json}) do
    {:text, json}
  end
end
