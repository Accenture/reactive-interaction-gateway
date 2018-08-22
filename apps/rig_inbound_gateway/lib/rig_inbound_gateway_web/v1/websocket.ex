defmodule RigInboundGatewayWeb.V1.Websocket do
  @moduledoc """
  Cowboy WebSocket handler.

  As soon as Phoenix pulls in Cowboy 2 this will have to be rewritten using the
  :cowboy_websocket behaviour.
  """

  require Logger
  alias RigInboundGateway.Events
  alias Rig.CloudEvent

  @behaviour :cowboy_websocket_handler

  @heartbeat_interval_ms 15_000

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  @impl :cowboy_websocket_handler
  def websocket_init(_type, req, _opts) do
    send(self(), :send_connection_token)
    Process.send_after(self(), :heartbeat, @heartbeat_interval_ms)
    {:ok, req, _state = %{}}
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
  def websocket_info({:rig_event, subscriber_group, cloud_event}, req, state) do
    Logger.debug(fn ->
      via = if is_nil(subscriber_group), do: "rig", else: inspect(subscriber_group)
      "[WS] #{via}: #{inspect(cloud_event)}"
    end)

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
  def websocket_info({:session_killed, group}, req, state) do
    Logger.info("[WS] session killed: #{inspect(group)}")
    # This will close the connection:
    out_frame = {:close, 4000, "Session killed."}
    {:reply, out_frame, req, state}
  end

  @impl :cowboy_websocket_handler
  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

  defp frame(%CloudEvent{} = cloud_event) do
    {:text, CloudEvent.serialize(cloud_event)}
  end
end
