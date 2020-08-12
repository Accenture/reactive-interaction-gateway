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
  test_with_server "Given response_from is set to Kafka and response is in binary mode, the custom http response code - 201 - should be used." do
    test_name = "proxy-http-response-from-kafka-binary-status-code"
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

    %HTTPoison.Response{status_code: res_status, body: res_body, headers: headers} =
      HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 201
    # ...extra headers are present
    assert Enum.member?(headers, {"content-type", "application/json; charset=utf-8"})
    # ...but the client got the response sent to the Kafka topic:
    assert Jason.decode!(res_body) == async_response

    RigKafka.Client.stop_supervised(kafka_client)
  end

  # @tag :kafka
  # test_with_server "Given response_from and target are set to Kafka, the http response is taken from the Kafka response topic instead of forwarding the backend's original response." do
  #   test_name = "proxy-http-response-from-kafka-target"
  #   topic = "rig-test"

  #   api_id = "mock-#{test_name}-api"
  #   endpoint_id = "mock-#{test_name}-endpoint"
  #   endpoint_path = "/#{endpoint_id}"
  #   async_response = %{"message" => "this is the async response that reaches the client instead"}
  #   kafka_config = kafka_config()

  #   callback = fn
  #     body, headers ->
  #       {:ok, event} = Cloudevents.from_kafka_message(body, headers)

  #       IO.inspect(event, label: "event")

  #       message =
  #         Jason.encode!(%{
  #           rig: %{correlation: get_in(event.extensions, ["rig", "correlation"]), response_code: 201},
  #           body: async_response
  #         })

  #       assert :ok == RigKafka.produce(kafka_config, config().response_topic, "", "response", message)

  #       # assert :ok ==
  #       #   RigKafka.produce(
  #       #     kafka_config,
  #       #     config().response_topic,
  #       #     "",
  #       #     "response",
  #       #     Jason.encode!(async_response),
  #       #     [
  #       #       {"rig-correlation", get_in(event.extensions, ["rig", "correlation"])},
  #       #       {"rig-response-code", "201"}
  #       #     ]
  #       #   )
  #   end

  #   {:ok, kafka_client} = RigKafka.start(kafka_config, callback)

  #   # We register the endpoint with the proxy:
  #   rig_api_url = "http://localhost:#{@api_port}/v2/apis"
  #   rig_proxy_url = "http://localhost:#{@proxy_port}"

  #   body =
  #     Jason.encode!(%{
  #       id: api_id,
  #       name: "Mock API",
  #       version_data: %{
  #         default: %{
  #           endpoints: [
  #             %{
  #               id: endpoint_id,
  #               method: "POST",
  #               path: endpoint_path,
  #               response_from: "kafka",
  #               target: "kafka",
  #               topic: topic
  #             }
  #           ]
  #         }
  #       },
  #       proxy: %{
  #         target_url: "localhost",
  #         port: FakeServer.port()
  #       }
  #     })

  #   headers = [{"content-type", "application/json"}]
  #   HTTPoison.post!(rig_api_url, body, headers)

  #   # The client calls the proxy endpoint:
  #   request_url = rig_proxy_url <> endpoint_path
  #   req_body =
  #     Jason.encode!(%{
  #       "event" => %{
  #         "specversion" => "0.2",
  #         "type" => "com.example.test",
  #         "source" => "/rig-test",
  #         "id" => "069711bf-3946-4661-984f-c667657b8d85",
  #         "time" => "2018-04-05T17:31:00Z",
  #         "data" => %{
  #           "foo" => "bar"
  #         }
  #       }
  #     })

  #   %HTTPoison.Response{status_code: res_status, body: res_body} = HTTPoison.post!(request_url, req_body)

  #   # Now we can assert that...
  #   # ...the connection is closed and the status is OK:
  #   assert res_status == 201
  #   # ...but the client got the response sent to the Kafka topic:
  #   assert Jason.decode!(res_body) == async_response

  #   RigKafka.Client.stop_supervised(kafka_client)
  # end
end
