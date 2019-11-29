defmodule RigInboundGatewayWeb.ConnectionInitTest do
  use ExUnit.Case, async: true

  require Logger

  alias HTTPoison
  alias Rig.Connection.Codec

  @base_url "http://localhost:4010/v2/connection"

  describe "Initialize connection" do
    test "An SSE connection can be initialized in advance." do
      url = "#{@base_url}/init"
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)

      assert {:ok, client} = SseClient.connect(connection_token: body)
      {event, client} = SseClient.read_welcome_event(client)

      assert Codec.deserialize(event["data"]["connection_token"]) == Codec.deserialize(body)

      SseClient.disconnect(client)
    end

    test "A client can connect to a destroyed VConnection and will get assigned a new VConnection." do
      url = "#{@base_url}/init"
      %HTTPoison.Response{body: body} = HTTPoison.get!(url)

      # Destroy the VConnection
      del_url = "#{@base_url}/#{body}"
      %HTTPoison.Response{} = HTTPoison.delete!(del_url)

      assert {:ok, client} = SseClient.connect(connection_token: body)
      {event, client} = SseClient.read_welcome_event(client)

      assert Codec.deserialize(event["data"]["connection_token"]) != Codec.deserialize(body)

      SseClient.disconnect(client)
    end
  end
end
