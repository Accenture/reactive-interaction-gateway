defmodule RigTests.Avro.AvroTest do
  @moduledoc """
  With `avro` enabled, Kafka producer and consumer should handle encoding and decoding.
  """

  use Rig.Config, [
    :brokers,
    :serializer,
    :schema_registry_host,
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
      :ok = RigKafka.Client.stop_supervised(kafka_client)
    end)

    :ok
  end

  @tag :avro
  test "Given avro is enabled, the producer should be able to encode message with required cloud events(0.1) fields and consumer decode message" do
    event = %{
      "cloudEventsVersion" => "0.1",
      "eventType" => "rig.avro.test1",
      "source" => "/test-producer",
      "eventID" => "1",
      "data" => %{
        "foo" => "avro required"
      }
    }

    kafka_config = kafka_config()
    :timer.sleep(5_000)

    assert :ok ==
             RigKafka.produce(
               kafka_config,
               "rig-avro",
               "rig-avro-value",
               "response",
               Jason.encode!(event)
             )

    assert_receive received_msg, 10_000

    assert Jason.decode!(received_msg) == event
  end

  @tag :avro
  test "Given avro is enabled, the producer should be able to encode message with optional cloud events(0.1) fields and consumer decode message" do
    event = %{
      "cloudEventsVersion" => "0.1",
      "eventType" => "rig.avro",
      "source" => "/test-producer",
      "eventID" => "1",
      "rig" => %{"a" => %{"b" => "c"}},
      "eventTime" => "2019-02-21T09:17:23.137Z",
      "contentType" => "avro/binary",
      "data" => %{
        "foo" => "avro optional"
      }
    }

    kafka_config = kafka_config()
    :timer.sleep(5_000)

    assert :ok ==
             RigKafka.produce(
               kafka_config,
               "rig-avro",
               "rig-avro-value",
               "response",
               Jason.encode!(event)
             )

    assert_receive received_msg, 10_000

    assert Jason.decode!(received_msg) == event
  end

  @tag :avro
  test "Given avro is enabled, the producer should be able to encode message with required cloud events(0.2) fields and consumer decode message" do
    event =
      Jason.encode!(%{
        specversion: "0.2",
        type: "rig.avro.test1",
        source: "/test-producer",
        id: "1",
        data: %{
          foo: "avro required"
        }
      })

    kafka_config = kafka_config()
    :timer.sleep(5_000)
    assert :ok == RigKafka.produce(kafka_config, "rig-avro", "rig-avro-value", "response", event)

    assert_receive received_msg, 10_000

    assert received_msg == event
  end

  @tag :avro
  test "Given avro is enabled, the producer should be able to encode message with optional cloud events(0.2) fields and consumer decode message" do
    event = %{
      "specversion" => "0.2",
      "type" => "rig.avro",
      "source" => "/test-producer",
      "id" => "1",
      "rig" => %{"a" => %{"b" => "c"}},
      "time" => "2019-02-21T09:17:23.137Z",
      "contenttype" => "avro/binary",
      "data" => %{
        "foo" => "avro optional"
      }
    }

    kafka_config = kafka_config()
    :timer.sleep(5_000)

    assert :ok ==
             RigKafka.produce(
               kafka_config,
               "rig-avro",
               "rig-avro-value",
               "response",
               Jason.encode!(event)
             )

    assert_receive received_msg, 10_000

    assert Jason.decode!(received_msg) == event
  end

  @tag :avro
  test "Given avro is enabled, the producer should be able to encode message without any cloud events fields and consumer decode message" do
    event =
      Jason.encode!(%{
        data: %{
          foo: "avro just data"
        }
      })

    kafka_config = kafka_config()
    :timer.sleep(5_000)
    assert :ok == RigKafka.produce(kafka_config, "rig-avro", "rig-avro-value", "response", event)

    assert_receive received_msg, 10_000

    assert received_msg == event
  end
end
