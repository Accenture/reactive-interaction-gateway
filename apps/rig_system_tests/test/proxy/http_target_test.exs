defmodule RigSystemTests.Proxy.HttpTargetTest do
  @moduledoc """
  Tests HTTP endpoints that operate sync or async against client expectations.

  Note that `test_with_server` sets up an HTTP server mock, which is then configured
  using the `route` macro.
  """
  use ExUnit.Case, async: false
  import FakeServer
  alias FakeServer.HTTP.Response

  @api_port Confex.fetch_env!(:rig_api, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][:port]

  @tag :wip
  test_with_server """
  When the client expects a sync response,
  given a sync backend,
  the http response is forwarded as-is.
  """ do
    endpoint_id = "mock-sync-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "is forwarded as-is to the client."}

    route(
      endpoint_path,
      Response.ok(sync_response, %{"content-type" => "application/json"})
    )

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v1/apis"
    rig_proxy_url = "http://localhost:#{@proxy_port}"

    body =
      Jason.encode!(%{
        id: "mock-api",
        name: "Mock API",
        version_data: %{
          default: %{
            endpoints: [
              %{
                id: endpoint_id,
                type: "http",
                not_secured: true,
                mode: "sync",
                method: "GET",
                path: endpoint_path
              }
            ]
          }
        },
        proxy: %{
          target_url: FakeServer.env().ip,
          port: FakeServer.env().port
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

  test_with_server """
  When the client expects a sync response,
  given an async backend,
  the http response is taken from a Kafka topic instead of forwarding the backend's original response.
  """ do
  end

  test_with_server """
  When the client expects an async response,
  the http response is forwarded as-is (regardless of how the backend operates).
  """ do
  end
end
