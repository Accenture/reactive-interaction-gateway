defmodule RigInboundGatewayWeb.OnlineTest do
  use ExUnit.Case, async: true

  require Logger

  alias HTTPoison

  @event_hub_http_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  describe "Check online status" do
    test "A connection can be initalized in advance and will show the online status 'offline'" do
      base_url = "http://localhost:#{@event_hub_http_port}/_rig/v1"
      api_url = "http://localhost:4010/v2"

      %HTTPoison.Response{body: connection_token, status_code: status} =
        HTTPoison.get!("#{base_url}/connection/init")

      assert status >= 200 and status <= 299

      auth =
        "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5YWIxYmZmMi1hOGQ4LTQ1NWMtYjQ4YS01MDE0NWQ3ZDhlMzAiLCJuYW1lIjoiSm9obiBEb2UiLCJpYXQiOjE1Njg3MTMzNjEsImV4cCI6NDEwMzI1ODE0M30.kjiR7kFyOEeMJaY1zPCctut39eEWmKswUCNZdK5Q3-w"

      meta = "{ \"metadata\": { \"locale\": \"de-AT\", \"timezone\": \"GMT+2\" } }"

      %HTTPoison.Response{status_code: status} =
        HTTPoison.put!("#{base_url}/connection/sse/#{connection_token}/metadata", meta, [
          {"Authorization", auth}
        ])

      assert status >= 200 and status <= 299

      jwt = "9ab1bff2-a8d8-455c-b48a-50145d7d8e30"

      assert %HTTPoison.Response{body: "offline"} =
               HTTPoison.get!(
                 "#{api_url}/connection/online?query_value=#{jwt}&query_field=userid"
               )

      assert {:ok, client} = SseClient.connect(connection_token: connection_token)

      assert %HTTPoison.Response{body: "online"} =
               HTTPoison.get!(
                 "#{api_url}/connection/online?query_value=#{jwt}&query_field=userid"
               )

      SseClient.disconnect(client)
    end
  end
end
