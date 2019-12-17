defmodule RigInboundGatewayWeb.OnlineTest do
  use ExUnit.Case, async: true

  require Logger

  alias HTTPoison

  @event_hub_http_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  describe "Set metadata" do
    test "Metadata can be set and retrieved" do
      base_url = "http://localhost:#{@event_hub_http_port}/_rig/v1"
      api_url = "http://localhost:4010/v2"

      %HTTPoison.Response{body: connection_token} = HTTPoison.get!("#{base_url}/connection/init")

      auth =
        "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5YWIxYmZmMi1hOGQ4LTQ1NWMtYjQ4YS01MDE0NWQ3ZDhlMzAiLCJuYW1lIjoiSm9obiBEb2UiLCJpYXQiOjE1Njg3MTMzNjEsImV4cCI6NDEwMzI1ODE0M30.kjiR7kFyOEeMJaY1zPCctut39eEWmKswUCNZdK5Q3-w"
      meta = "{ \"metadata\": { \"locale\": \"de-AT\", \"timezone\": \"GMT+2\" } }"
      HTTPoison.put!("#{base_url}/connection/sse/#{connection_token}/metadata", meta, [
        {"Authorization", auth}
      ])

      #HACK: RIG is too slow with registering the metadata (too slow means a couple of ms too slow)
      :timer.sleep(1000)

      jwt = "9ab1bff2-a8d8-455c-b48a-50145d7d8e30"
      assert %HTTPoison.Response{body: metadata} =
               HTTPoison.get!(
                 "#{api_url}/connection/metadata?query_value=#{jwt}&query_field=userid"
               )
      
      assert [%{"locale" => "de-AT","timezone" => "GMT+2","userid" => "9ab1bff2-a8d8-455c-b48a-50145d7d8e30"}] == Jason.decode!(metadata)
    end
  end
end
