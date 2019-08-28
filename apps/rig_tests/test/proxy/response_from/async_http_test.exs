defmodule RigTests.Proxy.ResponseFrom.AsyncHttpTest do
  @moduledoc """
  If `response_from` is set to http_async, the response is taken from internal HTTP endpoint /v1/responses

  Note that `test_with_server` sets up an HTTP server mock, which is then configured
  using the `route` macro.
  """
  # cause FakeServer opens a port:
  use ExUnit.Case, async: false

  import FakeServer
  import Plug.Conn, only: [put_req_header: 3]
  import Phoenix.ConnTest, only: [post: 3, build_conn: 0]

  alias FakeServer.Response

  @endpoint RigApi.Endpoint
  @api_port Confex.fetch_env!(:rig, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  test_with_server "Given response_from is set to http_async, the http response is taken from the internal HTTP endpoint." do
    test_name = "proxy-http-response-from-http-internal"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      event =
        Jason.encode!(%{
          specversion: "0.2",
          type: "rig.async-response",
          source: "fake-service",
          id: "1",
          rig: %{correlation: correlation_id},
          data: async_response
        })

      build_conn()
      |> put_req_header("content-type", "application/json;charset=utf-8")
      |> post("/v1/responses", event)

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v1/apis"
    rig_proxy_url = "http://localhost:#{@proxy_port}"

    body =
      Jason.encode!(%{
        id: api_id,
        name: "Mock API",
        version_data: %{
          default: %{
            endpoints: [
              %{
                id: endpoint_id,
                type: "http",
                method: "GET",
                path: endpoint_path,
                response_from: "http_async"
              }
            ]
          }
        },
        proxy: %{
          target_url: "localhost",
          port: FakeServer.port()
        }
      })

    headers = [{"content-type", "application/json"}]
    HTTPoison.post!(rig_api_url, body, headers)

    # The client calls the proxy endpoint:
    request_url = rig_proxy_url <> endpoint_path
    %HTTPoison.Response{status_code: res_status, body: res_body} = HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 200
    # ...the client never saw the http response:
    assert Jason.decode!(res_body) != sync_response
    # ...but the client got the response sent to the HTTP internal endpoint:
    assert Jason.decode!(res_body)["data"] == async_response
  end
end
