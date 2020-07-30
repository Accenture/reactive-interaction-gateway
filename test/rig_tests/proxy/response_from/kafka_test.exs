defmodule RigTests.Proxy.ResponseFrom.KafkaTest do
  @moduledoc """
  With `response_from` set to Kafka, the response is taken from a Kafka topic.

  In production, this may be used to hide asynchronous processing by one or more
  backend services with a synchronous interface.

  Note that `test_with_server` sets up an HTTP server mock, which is then configured
  using the `route` macro.
  """
  use Rig.Config, [
    :brokers,
    :consumer_topics,
    :ssl_enabled?,
    :ssl_ca_certfile,
    :ssl_certfile,
    :ssl_keyfile,
    :ssl_keyfile_pass,
    :sasl,
    :response_topic
  ]

  use ExUnit.Case, async: false

  import FakeServer

  alias FakeServer.Response
  alias Rig.KafkaConfig, as: RigKafkaConfig
  alias RigInboundGateway.ApiProxyInjection
  alias RigKafka

  @api_port Confex.fetch_env!(:rig, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  defp kafka_config, do: RigKafkaConfig.parse(config())

  setup_all do
    ApiProxyInjection.set()

    on_exit(fn ->
      ApiProxyInjection.restore()
    end)
  end

  setup do
    kafka_config = kafka_config()
    {:ok, kafka_client} = RigKafka.start(kafka_config)

    on_exit(fn ->
      :ok = RigKafka.Client.stop_supervised(kafka_client)
    end)

    :ok
  end

  @tag :kafka
  test_with_server "Given response_from is set to Kafka, the http response is taken from the Kafka response topic instead of forwarding the backend's original response." do
    test_name = "proxy-http-response-from-kafka"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    %{response_topic: kafka_topic} = config()
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"message" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    # The following service fake also shows how a real service should
    # wrap its response in a CloudEvent:
    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      message =
        Jason.encode!(%{
          rig: %{correlation: correlation_id},
          body: Jason.encode!(async_response)
        })

      kafka_config = kafka_config()
      assert :ok == RigKafka.produce(kafka_config, kafka_topic, "", "response", message)
      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                path: endpoint_path,
                response_from: "kafka"
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
    # ...but the client got the response sent to the Kafka topic:
    assert Jason.decode!(res_body) == async_response
  end

  @tag :kafka
  test_with_server "Given response_from is set to Kafka, the custom http response code - 201 - is taken from the Kafka response topic." do
    test_name = "proxy-http-response-from-kafka-status-code"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    %{response_topic: kafka_topic} = config()
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"message" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    # The following service fake also shows how a real service should
    # wrap its response in a CloudEvent:
    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      message =
        Jason.encode!(%{
          rig: %{correlation: correlation_id, response_code: 201},
          body: Jason.encode!(async_response)
        })

      kafka_config = kafka_config()
      assert :ok == RigKafka.produce(kafka_config, kafka_topic, "", "response", message)
      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                path: endpoint_path,
                response_from: "kafka"
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
    assert res_status == 201
    # ...but the client got the response sent to the Kafka topic:
    assert Jason.decode!(res_body) == async_response
  end

  @tag :kafka
  test_with_server "Given response_from is set to Kafka and response is in binary mode, the http response should include only body content." do
    test_name = "proxy-http-response-from-kafka-binary"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    %{response_topic: kafka_topic} = config()
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"message" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    # The following service fake also shows how a real service should
    # wrap its response in a CloudEvent:
    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      kafka_config = kafka_config()

      assert :ok ==
               RigKafka.produce(
                 kafka_config,
                 kafka_topic,
                 "",
                 "response",
                 Jason.encode!(async_response),
                 [
                   {"rig-correlation", correlation_id}
                 ]
               )

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                path: endpoint_path,
                response_from: "kafka"
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
    # ...but the client got the response sent to the Kafka topic:
    assert Jason.decode!(res_body) == async_response
  end

  @tag :kafka
  test_with_server "Given response_from is set to Kafka, the provided headers are forwarded to client." do
    test_name = "proxy-http-response-from-kafka-headers"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    %{response_topic: kafka_topic} = config()
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"message" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    # The following service fake also shows how a real service should
    # wrap its response in a CloudEvent:
    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      message =
        Jason.encode!(%{
          rig: %{correlation: correlation_id},
          body: Jason.encode!(async_response),
          headers: %{foo: "bar"}
        })

      kafka_config = kafka_config()
      assert :ok == RigKafka.produce(kafka_config, kafka_topic, "", "response", message)

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                path: endpoint_path,
                response_from: "kafka"
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

    %HTTPoison.Response{status_code: res_status, body: res_body, headers: res_headers} =
      HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 200
    # ...but the client got the response sent to the Kafka topic:
    assert Jason.decode!(res_body) == async_response
    assert Enum.member?(res_headers, {"foo", "bar"})
  end

  @tag :kafka
  test_with_server "Given response_from is set to Kafka and response is in binary mode, the custom http response code - 201 - should be used." do
    test_name = "proxy-http-response-from-kafka-binary-status-code"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    %{response_topic: kafka_topic} = config()
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"message" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    # The following service fake also shows how a real service should
    # wrap its response in a CloudEvent:
    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      kafka_config = kafka_config()

      assert :ok ==
               RigKafka.produce(
                 kafka_config,
                 kafka_topic,
                 "",
                 "response",
                 Jason.encode!(async_response),
                 [
                   {"rig-correlation", correlation_id},
                   {"rig-response-code", "201"}
                 ]
               )

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                path: endpoint_path,
                response_from: "kafka"
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
    assert res_status == 201
    # ...but the client got the response sent to the Kafka topic:
    assert Jason.decode!(res_body) == async_response
  end

  @tag :avro
  test_with_server "Given response_from is set to Kafka and response is in avro format, the http response should be correctly decoded and forwarded." do
    test_name = "proxy-http-response-from-kafka-avro"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    %{response_topic: kafka_topic} = config()
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"message" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    # The following service fake also shows how a real service should
    # wrap its response in a CloudEvent:
    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      event =
        Jason.encode!(%{
          specversion: "0.2",
          type: "rig.async-response",
          source: "fake-service",
          id: "3",
          rig: %{correlation: correlation_id},
          data: async_response
        })

      kafka_config = kafka_config()

      assert :ok ==
               RigKafka.produce(
                 kafka_config,
                 kafka_topic,
                 "rig-proxy-avro-value",
                 "response",
                 event,
                 []
               )

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                path: endpoint_path,
                response_from: "kafka"
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

    :timer.sleep(25_000)
    %HTTPoison.Response{status_code: res_status, body: res_body} = HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 200
    # ...but the client got the response sent to the Kafka topic:
    assert Jason.decode!(res_body) == async_response
  end
end
