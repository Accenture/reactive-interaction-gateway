defmodule RigInboundGatewayWeb.ConnectionInitTest do
  use ExUnit.Case, async: true

  require Logger

  alias HTTPoison
  alias Rig.Connection.Codec

  @event_hub_http_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  describe "Initialize connection" do
    test "then connect to it" do
      url = "http://localhost:#{@event_hub_http_port}/_rig/v1/connection/init"
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)
  
      assert {:ok, client} = SseClient.connect([connection_token: body])
      {event, _} = SseClient.read_welcome_event(client)
  
      assert Codec.deserialize(event["data"]["connection_token"]) == Codec.deserialize(body)
  
      SseClient.disconnect(client)
    end
  
    @tag timeout: 130_000
    test "then wait for it to time out and connect to it" do
      url = "http://localhost:#{@event_hub_http_port}/_rig/v1/connection/init"
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)
  
      # Destroy the VConnection
      delUrl = "http://localhost:#{@event_hub_http_port}/_rig/v1/connection/#{body}/vconnection"
      %HTTPoison.Response{} = HTTPoison.delete!(delUrl)
  
      assert {:ok, client} = SseClient.connect([connection_token: body])
      {event, _} = SseClient.read_welcome_event(client)
  
      assert Codec.deserialize(event["data"]["connection_token"]) != Codec.deserialize(body)
  
      SseClient.disconnect(client)
    end
  end
end