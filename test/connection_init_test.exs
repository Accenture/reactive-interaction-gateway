defmodule RigInboundGatewayWeb.ConnectionInitTest do
  use ExUnit.Case, async: true

  require Logger

  alias HTTPoison
  alias Rig.Connection.Codec

  @event_hub_http_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  describe "Initialize connection" do
    test "An SSE connection can be initialized in advance." do
      url = "http://localhost:#{@event_hub_http_port}/_rig/v1/connection/init"
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)
  
      assert {:ok, client} = SseClient.connect([connection_token: body])
      {event, client} = SseClient.read_welcome_event(client)
  
      assert Codec.deserialize(event["data"]["connection_token"]) == Codec.deserialize(body)
  
      SseClient.disconnect(client)
    end
  
    @tag timeout: 130_000
    test "A client can connect to a destroyed VConnection and will get assigned a new VConnection." do
      url = "http://localhost:#{@event_hub_http_port}/_rig/v1/connection/init"
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)
  
      # Destroy the VConnection
      del_url = "http://localhost:#{@event_hub_http_port}/_rig/v1/connection/#{body}"
      %HTTPoison.Response{} = HTTPoison.delete!(del_url)
  
      assert {:ok, client} = SseClient.connect([connection_token: body])
      {event, client} = SseClient.read_welcome_event(client)
  
      assert Codec.deserialize(event["data"]["connection_token"]) != Codec.deserialize(body)
  
      SseClient.disconnect(client)
    end
  end
end