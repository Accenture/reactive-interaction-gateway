defmodule RigTests.Proxy.RequestLogger.KafkaTest do
  @moduledoc """
  When API Gateway request arrives, event is published to Kafka topic.
  """
  use Rig.Config, [
    :brokers,
    :consumer_topics,
    :ssl_enabled?,
    :ssl_ca_certfile,
    :ssl_certfile,
    :ssl_keyfile,
    :ssl_keyfile_pass,
    :sasl
  ]

  use ExUnit.Case, async: false

  import FakeServer

  alias FakeServer.Response
  alias Rig.KafkaConfig, as: RigKafkaConfig
  alias RigInboundGateway.ApiProxyInjection
  alias RigInboundGateway.ProxyConfig
  alias RigKafka

  @api_port Confex.fetch_env!(:rig, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]
  @env [port: 55_001]

  defp kafka_config, do: RigKafkaConfig.parse(config())

  setup_all do
    ApiProxyInjection.set()

    on_exit(fn ->
      ApiProxyInjection.restore()
    end)
  end

  setup do
    System.put_env("REQUEST_LOG", "kafka")
    kafka_config = kafka_config()

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
        :ok
    end

    {:ok, kafka_client} = RigKafka.start(kafka_config, callback)

    on_exit(fn ->
      :ok = RigKafka.Client.stop_supervised(kafka_client)
    end)

    :ok
  end

  @tag :kafka
  test_with_server "Given request logger is set to Kafka, the http request should publish message to Kafka topic",
                   @env do
    test_name = "proxy-logger-kafka"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
    rig_proxy_url = "http://localhost:#{@proxy_port}"

    route(endpoint_path, Response.ok!(~s<{"status":"ok"}>))

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
                path: endpoint_path
              }
            ]
          }
        },
        proxy: %{
          target_url: "localhost",
          port: 55_001
        }
      })

    headers = [{"content-type", "application/json"}]
    HTTPoison.post!(rig_api_url, body, headers)

    # The client calls the proxy endpoint:
    request_url = rig_proxy_url <> endpoint_path

    :timer.sleep(5_000)

    HTTPoison.post!(request_url, "", headers)

    assert_receive received_msg, 10_000
    received_msg_map = Jason.decode!(received_msg)

    System.delete_env("REQUEST_LOG")

    # Type
    assert get_in(received_msg_map, ["type"]) == "com.rig.proxy.api.call"

    # Endpoint
    assert get_in(received_msg_map, ["data", "endpoint", "id"]) == endpoint_id
    assert get_in(received_msg_map, ["data", "endpoint", "method"]) == "POST"
    assert get_in(received_msg_map, ["data", "endpoint", "path"]) == endpoint_path

    # IP
    assert get_in(received_msg_map, ["data", "remote_ip"]) == "127.0.0.1"

    # Path
    assert get_in(received_msg_map, ["data", "request_path"]) == endpoint_path
  end

  @tag :avro
  test_with_server "Given request logger is set to Kafka and Avro enabled, the http request
  should publish message to Kafka topic",
                   @env do
    kafka_request_avro_orig_value = ProxyConfig.set("PROXY_KAFKA_REQUEST_AVRO", "")
    test_name = "proxy-logger-kafka-avro"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
    rig_proxy_url = "http://localhost:#{@proxy_port}"

    route(endpoint_path, Response.ok!(~s<{"status":"ok"}>))

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
                path: endpoint_path
              }
            ]
          }
        },
        proxy: %{
          target_url: "localhost",
          port: 55_001
        }
      })

    headers = [{"content-type", "application/json"}]
    HTTPoison.post!(rig_api_url, body, headers)

    # The client calls the proxy endpoint:
    request_url = rig_proxy_url <> endpoint_path

    :timer.sleep(5_000)

    %HTTPoison.Response{status_code: res_status, body: res_body} =
      HTTPoison.post!(request_url, "", headers)

    assert res_status == 200
    assert res_body == "{\"status\":\"ok\"}"

    assert_receive received_msg, 10_000
    received_msg_map = Jason.decode!(received_msg)

    System.delete_env("REQUEST_LOG")

    # Endpoint
    assert get_in(received_msg_map, ["data", "endpoint", "id"]) == endpoint_id
    assert get_in(received_msg_map, ["data", "endpoint", "method"]) == "POST"
    assert get_in(received_msg_map, ["data", "endpoint", "path"]) == endpoint_path

    # IP
    assert get_in(received_msg_map, ["data", "remote_ip"]) == "127.0.0.1"

    # Path
    assert get_in(received_msg_map, ["data", "request_path"]) == endpoint_path
    ProxyConfig.restore("PROXY_KAFKA_REQUEST_TOPIC", kafka_request_avro_orig_value)
  end
end
