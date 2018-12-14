defmodule RigTests.Proxy.PublishToEventStream.KafkaTest do
  @moduledoc """
  With `target` set to Kafka, the body from HTTP request is published to Kafka topic.
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

  alias Rig.KafkaConfig, as: RigKafkaConfig
  alias RigKafka

  @api_port Confex.fetch_env!(:rig_api, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:http][:port]
  @proxy_host Confex.fetch_env!(:rig_inbound_gateway, RigInboundGatewayWeb.Endpoint)[:url][:host]

  defp kafka_config, do: RigKafkaConfig.parse(config())

  setup do
    kafka_config = kafka_config()

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
        :ok
    end

    {:ok, kafka_client} = RigKafka.start(kafka_config, callback)

    on_exit(fn ->
      RigKafka.Client.stop_supervised(kafka_client)
    end)

    :ok
  end

  @tag :kafka
  test "Given target is set to Kafka, the http OPTIONS request should handle CORS" do
    test_name = "proxy-publish-to-kafka-cors"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"

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
                method: "OPTIONS",
                path: endpoint_path,
                target: "kafka"
              }
            ]
          }
        },
        proxy: %{
          target_url: "http://localhost",
          port: 3000
        }
      })

    headers = [{"content-type", "application/json"}]
    HTTPoison.post!(rig_api_url, body, headers)

    # The client calls the proxy endpoint:
    request_url = rig_proxy_url <> endpoint_path

    %HTTPoison.Response{status_code: res_status, body: res_body, headers: res_headers} =
      HTTPoison.options!(request_url, headers)

    assert res_status == 204
    assert res_body == ""

    # CORS should verify origin
    assert Enum.member?(res_headers, {"access-control-allow-origin", "*"})
    # CORS should verify HTTP methods
    assert Enum.member?(res_headers, {"access-control-allow-methods", "*"})
    # CORS should verify allowed headers
    assert Enum.member?(
             res_headers,
             {"access-control-allow-headers", "content-type,authorization"}
           )
  end

  @tag :kafka
  test "Given target is set to Kafka, the http request should publish message to Kafka topic" do
    test_name = "proxy-publish-to-kafka"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"

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
                method: "POST",
                path: endpoint_path,
                target: "kafka"
              }
            ]
          }
        },
        proxy: %{
          target_url: "http://localhost",
          port: 3000
        }
      })

    headers = [{"content-type", "application/json"}]
    HTTPoison.post!(rig_api_url, body, headers)

    # The client calls the proxy endpoint:
    request_url = rig_proxy_url <> endpoint_path

    kafka_body =
      Jason.encode!(%{
        "data" => %{
          "eventID" => "069711bf-3946-4661-984f-c667657b8d85",
          "eventType" => "com.example.test",
          "eventTypeVersion" => "1.0",
          "eventTime" => "2018-04-05T17:31:00Z",
          "cloudEventsVersion" => "0.1",
          "source" => "/rig-test",
          "contentType" => "application/json",
          "extensions" => %{},
          "data" => %{
            "foo" => "bar"
          }
        },
        "partition_key" => "test_key"
      })

    %HTTPoison.Response{status_code: res_status, body: res_body} =
      HTTPoison.post!(request_url, kafka_body, headers)

    assert res_status == 202
    assert res_body == "Accepted."

    expected_msg =
      Jason.encode!(%{
        "source" => "rig-test",
        "rig" => %{
          "scheme" => "http",
          "requestPath" => "/mock-proxy-http-response-publish-to-kafka-endpoint",
          "reqHeaders" => [
            ["user-agent", "hackney/1.14.0"],
            ["host", "#{@proxy_host}:#{@proxy_port}"],
            ["content-type", "application/json"],
            ["content-length", "291"]
          ],
          "remoteIP" => "127.0.0.1",
          "queryString" => "",
          "port" => @proxy_port,
          "method" => "POST",
          "host" => @proxy_host,
          "correlationID" => "g2dkAA1ub25vZGVAbm9ob3N0AAADvgAAAAAA"
        },
        "extensions" => %{},
        "eventTypeVersion" => "1.0",
        "eventType" => "com.example.test",
        "eventTime" => "2018-04-05T17:31:00Z",
        "eventID" => "069711bf-3946-4661-984f-c667657b8d85",
        "data" => %{
          "foo" => "bar"
        },
        "contentType" => "application/json",
        "cloudEventsVersion" => "0.1"
      })

    assert_receive expected_msg, 10_000
  end
end
