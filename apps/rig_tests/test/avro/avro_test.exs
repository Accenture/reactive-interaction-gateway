defmodule RigTests.Avro.AvroTest do
  @moduledoc """
  With `avro` enabled, Kafka producer and consumer should handle encoding and decoding.
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
  alias RigTests.AvroConfig

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
  test "Given avro is enabled, the producer should be able to encode message with required cloud events(0.1) fields and consumer decode message" do
    AvroConfig.set("avro")

    event =
      Jason.encode!(%{
        cloudEventsVersion: "0.1",
        eventType: "rig.avro.test1",
        source: "/test-producer",
        eventID: "1",
        data: %{
          foo: "avro required"
        }
      })

    kafka_config = kafka_config()
    assert :ok == RigKafka.produce(kafka_config, "rigAvro", "rigAvro-value", "response", event)

    assert_receive received_msg, 10_000

    assert received_msg == %{
             data: %{"foo" => "avro required"},
             eventID: "1",
             source: "/test-producer",
             cloudEventsVersion: "0.1",
             eventType: "rig.avro.test1"
           }

    AvroConfig.restore()
  end

  @tag :kafka
  test "Given avro is enabled, the producer should be able to encode message with optional cloud events(0.1) fields and consumer decode message" do
    AvroConfig.set("avro")

    event =
      Jason.encode!(%{
        cloudEventsVersion: "0.1",
        eventType: "rig.avro",
        source: "/test-producer",
        eventID: "1",
        rig: %{a: %{b: "c"}},
        eventTime: "2019-02-21T09:17:23.137Z",
        contentType: "avro/binary",
        data: %{
          foo: "avro optional"
        }
      })

    kafka_config = kafka_config()
    assert :ok == RigKafka.produce(kafka_config, "rigAvro", "rigAvro-value", "response", event)

    assert_receive received_msg, 10_000

    assert received_msg == %{
             contentType: "avro/binary",
             data: %{"foo" => "avro optional"},
             eventID: "1",
             source: "/test-producer",
             cloudEventsVersion: "0.1",
             eventTime: "2019-02-21T09:17:23.137Z",
             eventType: "rig.avro",
             rig: %{"a" => %{"b" => "c"}}
           }

    AvroConfig.restore()
  end

  @tag :kafka
  test "Given avro is enabled, the producer should be able to encode message with required cloud events(0.2) fields and consumer decode message" do
    AvroConfig.set("avro")

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
    assert :ok == RigKafka.produce(kafka_config, "rigAvro", "rigAvro-value", "response", event)

    assert_receive received_msg, 10_000

    assert received_msg == %{
             data: %{"foo" => "avro required"},
             id: "1",
             source: "/test-producer",
             specversion: "0.2",
             type: "rig.avro.test1"
           }

    AvroConfig.restore()
  end

  @tag :kafka
  test "Given avro is enabled, the producer should be able to encode message with optional cloud events(0.2) fields and consumer decode message" do
    AvroConfig.set("avro")

    event =
      Jason.encode!(%{
        specversion: "0.2",
        type: "rig.avro",
        source: "/test-producer",
        id: "1",
        rig: %{a: %{b: "c"}},
        time: "2019-02-21T09:17:23.137Z",
        contenttype: "avro/binary",
        data: %{
          foo: "avro optional"
        }
      })

    kafka_config = kafka_config()
    assert :ok == RigKafka.produce(kafka_config, "rigAvro", "rigAvro-value", "response", event)

    assert_receive received_msg, 10_000

    assert received_msg == %{
             contenttype: "avro/binary",
             data: %{"foo" => "avro optional"},
             id: "1",
             source: "/test-producer",
             specversion: "0.2",
             time: "2019-02-21T09:17:23.137Z",
             type: "rig.avro",
             rig: %{"a" => %{"b" => "c"}}
           }

    AvroConfig.restore()
  end

  @tag :kafka
  test "Given avro is enabled, the producer should be able to encode message without any cloud events fields and consumer decode message" do
    AvroConfig.set("avro")

    event =
      Jason.encode!(%{
        data: %{
          foo: "avro just data"
        }
      })

    kafka_config = kafka_config()
    assert :ok == RigKafka.produce(kafka_config, "rigAvro", "rigAvro-value", "response", event)

    assert_receive received_msg, 10_000

    assert received_msg == %{
             data: %{"foo" => "avro just data"}
           }

    AvroConfig.restore()
  end

  @tag :kafka
  test "Given avro is enabled, the producer and consumer should be able to fallback to non-encoding(decoding) behavior" do
    AvroConfig.set("avro")

    event = "Simple unstructured event"

    kafka_config = kafka_config()
    assert :ok == RigKafka.produce(kafka_config, "rigAvro", "rigAvro-value", "response", event)

    assert_receive received_msg, 10_000
    assert received_msg == "Simple unstructured event"

    AvroConfig.restore()
  end
end
