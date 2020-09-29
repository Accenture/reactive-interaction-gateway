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
      body, headers ->
        {:ok, event} = Cloudevents.from_kafka_message(body, headers)
        send(test_pid, event)
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

    expected_event = %Cloudevents.Format.V_0_1.Event{
      cloudEventsVersion: "0.1",
      contentType: "application/json",
      data: %{"foo" => "avro required"},
      eventID: "1",
      eventTime: nil,
      eventType: "rig.avro.test1",
      extensions: %{},
      schemaURL: nil,
      source: "/test-producer"
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

    assert received_msg == expected_event
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

    expected_event = %Cloudevents.Format.V_0_1.Event{
      cloudEventsVersion: "0.1",
      contentType: "avro/binary",
      data: %{"foo" => "avro optional"},
      eventID: "1",
      eventTime: "2019-02-21T09:17:23.137Z",
      eventType: "rig.avro",
      extensions: %{"rig" => %{"a" => %{"b" => "c"}}},
      schemaURL: nil,
      source: "/test-producer"
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

    assert received_msg == expected_event
  end

  @tag :avro
  test "Given avro is enabled, the producer should be able to encode message with required cloud events(0.2) fields and consumer decode message" do
    event = %{
      specversion: "0.2",
      type: "rig.avro.test1",
      source: "/test-producer",
      id: "1",
      data: %{
        "foo" => "avro required"
      }
    }

    expected_event = %Cloudevents.Format.V_0_2.Event{
      contenttype: "application/json",
      data: %{"foo" => "avro required"},
      extensions: %{},
      id: "1",
      schemaurl: nil,
      source: "/test-producer",
      specversion: "0.2",
      time: nil,
      type: "rig.avro.test1"
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

    assert received_msg == expected_event
  end

  @tag :avro
  test "Given avro is enabled, the producer should be able to encode message with optional cloud events(0.2) fields and consumer decode message" do
    event = %{
      specversion: "0.2",
      type: "rig.avro",
      source: "/test-producer",
      id: "1",
      rig: %{"a" => %{"b" => "c"}},
      time: "2019-02-21T09:17:23.137Z",
      contenttype: "avro/binary",
      data: %{
        "foo" => "avro optional"
      }
    }

    expected_event = %Cloudevents.Format.V_0_2.Event{
      contenttype: "avro/binary",
      data: %{"foo" => "avro optional"},
      id: "1",
      source: "/test-producer",
      specversion: "0.2",
      time: "2019-02-21T09:17:23.137Z",
      type: "rig.avro",
      extensions: %{"rig" => %{"a" => %{"b" => "c"}}},
      schemaurl: nil
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

    assert received_msg == expected_event
  end
end
