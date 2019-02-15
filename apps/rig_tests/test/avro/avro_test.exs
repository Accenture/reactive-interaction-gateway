defmodule RigTests.Avro.AvroTest do
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
  test "Given avro is enabled, the producer should be able to encode message and consumer decode message" do
    event =
      Jason.encode!(%{
        specversion: "0.2",
        type: "rig.avro",
        source: "/test-producer",
        id: "1",
        rig: %{a: "b"},
        data: %{
          foo: "avro test"
        }
      })

    kafka_config = kafka_config()
    assert :ok == RigKafka.produce(kafka_config, "rigAvro", "rigAvro-value", "response", event)
  end
end
