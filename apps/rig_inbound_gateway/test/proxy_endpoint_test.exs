defmodule RigInboundGateway.ProxyEndpointTest do
  @moduledoc """
  End-to-end tests for proxy endpoint configurations.

  """
  use ExUnit.Case, async: true

  import FakeServer

  @api_port Application.get_env(:rig_api, RigApi.Endpoint)[:http][:port]

  test_with_server """
  Given an "async"-type endpoint,
  when the target is set to an HTTP endpoint,
  the request is forwarded to the endpoint, but the response is taken from the response Kafka topic.
  """ do
    # First we need a fake endpoint that returns data that the client never sees. Note
    # that `test_with_server` already sets up the server itself, so we only configures
    # routes here:
    sync_response = %{this: "should not be seen"}

    route(
      "/mock-async-endpoint",
      Response.ok(sync_response, %{"content-type" => "application/json"})
    )

    # We register the endpoint with the proxy:
    url = "http://localhost:#{@api_port}/v1/apis"

    body =
      Jason.encode!(%{
        id: "mock-api",
        name: "Mock API",
        version_data: %{
          default: %{
            endpoints: [
              %{
                id: "mock-async-endpoint",
                path: "/mock-async-endpoint",
                method: "GET",
                type: "async",
                target: "kafka",
                topic: "test-topic",
                not_secured: true
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
    HTTPoison.post!(url, body, headers)

    # Time for the incoming HTTP request against the proxy endpoint:

    # We simulate an async response on the Kafka topic:

    # Now we can assert that...
    # ...the connection is closed and the status is OK:
    # ...the response received does not contain the synchronous response from the service mock:
    # ...the response contains the fake response from the Kafka response topic:
  end

  test """
  Given an "async"-type endpoint,
  when the target is set to a Kafka topic,
  the request is produced to the request Kafka topic and the response is taken from the response Kafka topic.
  """ do
  end

  test """
  Given an "sync"-type endpoint,
  when the target is set to an HTTP endpoint,
  the request is forwarded to the endpoint and the response is sent back to the client.
  """ do
  end

  test """
  Given an "sync"-type endpoint,
  when the target is set to a Kafka topic,
  the request is produced to the request Kafka topic, but the response is simply "accepted".
  """ do
  end
end
