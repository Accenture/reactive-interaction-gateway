defmodule RigSystemTests.Proxy.HttpTargetTest do
  @moduledoc """
  Tests HTTP endpoints that operate sync or async against client expectations.

  Note that `test_with_server` sets up an HTTP server mock, which is then configured
  using the `route` macro.
  """
  use ExUnit.Case, async: false
  import FakeServer
  alias FakeServer.HTTP.Response

  alias RigKafka

  @api_port Confex.fetch_env!(:rig_api, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][:port]

  @tag :wip
  test_with_server "Given response_from is not set, the http response is forwarded as-is." do
    test_name = "proxy-http-test-simple"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
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
        id: api_id,
        name: "Mock API",
        version_data: %{
          default: %{
            endpoints: [
              %{
                id: endpoint_id,
                type: "http",
                not_secured: true,
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

  test_with_server "Given response_from is set to a Kafka topic, the http response is taken from a Kafka topic instead of forwarding the backend's original response." do
    test_name = "proxy-http-test-async"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    kafka_topic = "#{test_name}"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"the client" => "never sees this response"}
    async_response = %{"this is the async response" => "that reaches the client instead"}

    route(endpoint_path, fn _ ->
      # TODO make sure to use the kafka consumer topic in the api config below
      # TODO produce async_response to that topic
      Response.ok(sync_response, %{"content-type" => "application/json"})
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
                not_secured: true,
                method: "GET",
                path: endpoint_path,
                response_from: %{
                  type: "kafka",
                  topic: kafka_topic
                }
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
    # ...the client never saw the http response:
    assert Jason.decode!(res_body) != sync_response
    # ...but the client got the response sent to the Kafka topic:
    assert Jason.decode!(res_body) == async_response
  end
end
