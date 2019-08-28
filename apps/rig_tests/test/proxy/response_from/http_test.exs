defmodule RigTests.Proxy.ResponseFrom.HttpTest do
  @moduledoc """
  If `response_from` is not set, the response is taken from the proxied request.

  Note that `test_with_server` sets up an HTTP server mock, which is then configured
  using the `route` macro.
  """
  # cause FakeServer opens a port:
  use ExUnit.Case, async: false

  import FakeServer

  alias FakeServer.Response

  @api_port Confex.fetch_env!(:rig, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  test_with_server "Given response_from is not set, the http response is forwarded as-is." do
    test_name = "proxy-http-sync-response"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "is forwarded as-is to the client."}

    route(
      endpoint_path,
      Response.ok!(sync_response, %{"content-type" => "application/json"})
    )

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
                secured: false,
                method: "GET",
                path: endpoint_path
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
    # ...the response received is exactly what the service mock returned:
    assert Jason.decode!(res_body) == sync_response
  end
end
