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

  @tag :kafka
  test_with_server "Given response_from is set to Kafka, the http response (code, content-type, body) is taken from the Kafka response topic instead of forwarding the backend's original response." do
    test_name = "proxy-http-response-from-kafka"
    kafka_config = kafka_config()
    {:ok, kafka_client} = RigKafka.start(kafka_config)
    %{response_topic: kafka_topic} = config()

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"

    sync_response = %{"message" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    # The fake backend service:
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
                   {"rig-response-code", "201"},
                   {"content-type", "application/json;charset=utf-8"}
                 ]
               )

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register this endpoint with the proxy:
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
                method: "GET",
                path_regex: endpoint_path,
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

    # The client sees only the asynchronous response:
    %HTTPoison.Response{status_code: res_status, body: res_body, headers: headers} =
      HTTPoison.get!(request_url)

    # The response code is taken from the async response (201) and not from the sync one (200):
    assert res_status == 201
    # Extra headers are present:
    assert Enum.member?(headers, {"content-type", "application/json;charset=utf-8"})
    # The body is taken from the async response as well:
    assert Jason.decode!(res_body) == async_response

    RigKafka.Client.stop_supervised(kafka_client)
  end

  @tag :kafka
  test_with_server "Given response_from is set to Kafka and response code is incorrect, the originating request should timeout." do
    test_name = "proxy-http-response-from-kafka-binary-status-code-timeout"
    kafka_config = kafka_config()
    {:ok, kafka_client} = RigKafka.start(kafka_config)

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
                   {"rig-response-code", "abc201"},
                   {"content-type", "application/json;charset=utf-8"}
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
                method: "GET",
                path_regex: endpoint_path,
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

    assert catch_error(HTTPoison.get!(request_url)) == %HTTPoison.Error{id: nil, reason: :timeout}

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1

    RigKafka.Client.stop_supervised(kafka_client)
  end

  @tag :kafka
  test_with_server "response_from and target can both be set to Kafka." do
    test_name = "proxy-http-response-from-kafka-target"
    topic = "rig-test"
    %{response_topic: response_topic} = config()

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    async_response = %{"message" => "this is the async response that reaches the client instead"}
    kafka_config = kafka_config()

    callback = fn
      body, headers ->
        {:ok, event} = Cloudevents.from_kafka_message(body, headers)

        assert :ok ==
                 RigKafka.produce(
                   kafka_config,
                   response_topic,
                   "",
                   "response",
                   Jason.encode!(async_response),
                   [
                     {"rig-correlation", get_in(event.extensions, ["rig", "correlation"])},
                     {"rig-response-code", "201"},
                     {"content-type", "application/json;charset=utf-8"}
                   ]
                 )
    end

    {:ok, kafka_client} = RigKafka.start(kafka_config, callback)

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
                method: "POST",
                path_regex: endpoint_path,
                response_from: "kafka",
                target: "kafka",
                topic: topic
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

    req_body =
      Jason.encode!(%{
        "specversion" => "0.2",
        "type" => "com.example.test",
        "source" => "/rig-test",
        "id" => "069711bf-3946-4661-984f-c667657b8d85",
        "time" => "2018-04-05T17:31:00Z",
        "data" => %{
          "foo" => "bar"
        }
      })

    # Wait for the Kafka consumer to get its assignments..
    :timer.sleep(15_000)

    %HTTPoison.Response{status_code: res_status, body: res_body, headers: headers} =
      HTTPoison.post!(request_url, req_body)

    # Status and body are both taken from the Kafka response:
    assert res_status == 201
    assert Jason.decode!(res_body) == async_response
    # Extra headers are present:
    assert Enum.member?(headers, {"content-type", "application/json;charset=utf-8"})

    RigKafka.Client.stop_supervised(kafka_client)
  end
end
