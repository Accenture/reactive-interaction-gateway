defmodule RigInboundGatewayWeb.ReconnectTest do
  use ExUnit.Case, async: true

  require Logger

  alias HTTPoison
  alias Rig.Connection.Codec

  @event_hub_http_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  test "Initialize connection, then disconnect and reconnect" do
    assert {:ok, client1} = SseClient.connect()
    {event1, _} = SseClient.read_welcome_event(client1)

    SseClient.disconnect(client1)

    SseClient.flush_mailbox()

    assert {:ok, client2} = SseClient.connect([connection_token: event1["data"]["connection_token"]])
    {event2, _} = SseClient.read_welcome_event(client2)
    SseClient.disconnect(client2)

    assert Codec.deserialize(event1["data"]["connection_token"]) == Codec.deserialize(event2["data"]["connection_token"])  
  end

  test "Initialize connection, disconnect, destroy the VConnection and reconnect" do
    assert {:ok, client1} = SseClient.connect()
    {event1, _} = SseClient.read_welcome_event(client1)

    SseClient.disconnect(client1)
    
    # Destroy the VConnection, this simulates a timeout
    url = "http://localhost:#{@event_hub_http_port}/_rig/v1/connection/#{event1["data"]["connection_token"]}/destroy"
    %HTTPoison.Response{status_code: 200} = HTTPoison.put!(url)

    SseClient.flush_mailbox()

    assert {:ok, client2} = SseClient.connect([connection_token: event1["data"]["connection_token"]])
    {event2, _} = SseClient.read_welcome_event(client2)
    SseClient.disconnect(client2)

    assert Codec.deserialize(event1["data"]["connection_token"]) != Codec.deserialize(event2["data"]["connection_token"])  
  end
end