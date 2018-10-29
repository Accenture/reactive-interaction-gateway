defmodule RigTests.Proxy.ResponseFrom.KinesisTest do
  @moduledoc """
  With `response_from` set to Kinesis, the response is taken from a Kinesis stream.

  In production, this may be used to hide asynchronous processing by one or more
  backend services with a synchronous interface.

  Note that `test_with_server` sets up an HTTP server mock, which is then configured
  using the `route` macro.
  """
  use Rig.Config, [:response_topic]
  use ExUnit.Case, async: false
  import FakeServer
  alias FakeServer.HTTP.Response

  @api_port Confex.fetch_env!(:rig_api, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][:port]

  # TODO kinesis config
  # @kafka_config RigKafka.Config.new(Application.fetch_env!(:rig, :systest_kafka_config))

  setup do
    # TODO start kinesis client

    on_exit(fn ->
      nil
      # TODO stop kinesis client
    end)

    :ok
  end

  @tag :kinesis
  test_with_server "Given response_from is set to Kinesis, the http response is taken from the Kinesis response stream instead of forwarding the backend's original response." do
    test_name = "proxy-http-response-from-kinesis"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    %{response_topic: _kinesis_stream} = config()
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"the client" => "never sees this response"}
    async_response = %{"this is the async response" => "that reaches the client instead"}

    route(endpoint_path, fn _ ->
      # TODO produce async_response to Kinesis stream
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
                response_from: "kinesis"
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
