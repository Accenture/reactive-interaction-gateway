defmodule RigKafkaTest do
  @moduledoc """
  Test suite for RIG's Kafka client.
  The suite does not use any mocks, because RigKafka is, for the most part, glue code
  on top of brod, the underlying Kafka client. The tests make sure that the setup
  works in general and that the behaviour of brod stays the same.
  There is also a recovery tests that shows how RIG deals with a network outage; see
  `RigKafka.NetworkOutageTest`.
  """
  use ExUnit.Case, async: false

  doctest RigKafka

  alias RigKafka
  alias RigKafka.Avro
  alias RigKafka.Config

  @schema_registry_host "localhost:8081"

  defp kafka_config(consumer_topics, serializer, schema_registry_host) do
    broker_env = System.get_env("KAFKA_BROKERS")
    assert not is_nil(broker_env), "KAFKA_BROKERS needs to be set for Kafka test to work"

    brokers =
      broker_env
      |> String.split(",")
      |> Enum.map(fn socket ->
        [host, port] = for part <- String.split(socket, ":"), do: String.trim(part)
        {host, String.to_integer(port)}
      end)

    Config.new(%{
      brokers: brokers,
      consumer_topics: consumer_topics,
      serializer: serializer,
      schema_registry_host: schema_registry_host,
      group_id: "rig"
    })
  end

  defp test_produce(client_id, topic, value, headers) do
    :ok =
      :brod.produce_sync(
        client_id,
        topic,
        0,
        "dummy-key",
        %{
          value: value,
          headers: headers
        }
      )
  end

  @tag :kafka
  test "Given a started RigKafka client, messages can be produced and consumed." do
    topic = "rig-kafka-test-simple-topic"
    serializer = nil
    schema_registry_host = ""

    config = kafka_config([topic], serializer, schema_registry_host)

    msg =
      Jason.encode!(%{
        "specversion" => "0.2",
        "type" => "com.example.test.simple",
        "source" => "/rig-test",
        "id" => "069711bf-3946-4661-984f-c667657b8d85",
        "data" => %{
          "foo" => "bar1"
        }
      })

    expected_msg = %Cloudevents.Format.V_0_2.Event{
      specversion: "0.2",
      type: "com.example.test.simple",
      source: "/rig-test",
      id: "069711bf-3946-4661-984f-c667657b8d85",
      data: %{
        "foo" => "bar1"
      },
      contenttype: "application/json",
      extensions: %{},
      schemaurl: nil,
      time: nil
    }

    test_pid = self()

    callback = fn
      body, headers ->
        {:ok, event} = Cloudevents.from_kafka_message(body, headers)
        send(test_pid, event)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)

    :timer.sleep(5_000)
    RigKafka.produce(config, topic, "", "test", msg)

    assert_receive received_msg, 10_000
    assert received_msg == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :kafka
  test "Consumer should use binary mode when content_type header is set, but not valid" do
    topic = "rig-kafka-test-simple-topic"
    serializer = nil
    schema_registry_host = ""

    config = kafka_config([topic], serializer, schema_registry_host)

    data = %{
      "foo" => "bar2"
    }

    expected_msg = %Cloudevents.Format.V_0_2.Event{
      specversion: "0.2",
      type: "com.example.test.simple",
      source: "/rig-test",
      id: "069711bf-3946-4661-984f-c667657b8d85",
      data: Jason.encode!(data),
      contenttype: "application/json",
      schemaurl: nil,
      extensions: %{"datacontenttype" => "some-weird-type"},
      time: nil
    }

    test_pid = self()

    callback = fn
      body, headers ->
        {:ok, event} = Cloudevents.from_kafka_message(body, headers)
        send(test_pid, event)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(config.client_id, topic, Jason.encode!(data), [
      {"content-type", "some-weird-type"},
      {"ce_specversion", "0.2"},
      {"ce_type", "com.example.test.simple"},
      {"ce_source", "/rig-test"},
      {"ce_id", "069711bf-3946-4661-984f-c667657b8d85"}
    ])

    assert_receive received_msg, 10_000
    assert received_msg == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :avro
  test "Consumer should use binary mode when content_type header is set and valid, but it's Avro" do
    topic = "rig-avro-test-simple-topic"
    serializer = "avro"
    schema_registry_host = @schema_registry_host

    config = kafka_config([topic], serializer, schema_registry_host)

    data = %{
      "foo" => "bar-avro1"
    }

    expected_msg = %Cloudevents.Format.V_0_2.Event{
      specversion: "0.2",
      type: "com.example.test.simple",
      source: "/rig-test",
      id: "069711bf-3946-4661-984f-c667657b8d85",
      data: data,
      contenttype: "application/json",
      extensions: %{},
      schemaurl: nil,
      time: nil
    }

    test_pid = self()

    callback = fn
      body, headers ->
        {:ok, event} = Cloudevents.from_kafka_message(body, headers)
        send(test_pid, event)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(
      config.client_id,
      topic,
      Avro.encode("rig-avro-test-simple-topic-value", data, @schema_registry_host),
      [
        {"content-type", "application/cloudevents+avro"},
        {"ce_specversion", "0.2"},
        {"ce_type", "com.example.test.simple"},
        {"ce_source", "/rig-test"},
        {"ce_id", "069711bf-3946-4661-984f-c667657b8d85"}
      ]
    )

    assert_receive received_msg, 10_000
    assert received_msg == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :kafka
  test "Consumer should use structured mode when content_type header is set, valid and JSON" do
    topic = "rig-kafka-test-simple-topic"
    serializer = nil
    schema_registry_host = ""

    config = kafka_config([topic], serializer, schema_registry_host)

    msg =
      Jason.encode!(%{
        "specversion" => "0.2",
        "type" => "com.example.test.simple",
        "source" => "/rig-test",
        "id" => "069711bf-3946-4661-984f-c667657b8d85",
        "data" => %{
          "foo" => "bar4"
        }
      })

    expected_msg = %Cloudevents.Format.V_0_2.Event{
      specversion: "0.2",
      type: "com.example.test.simple",
      source: "/rig-test",
      id: "069711bf-3946-4661-984f-c667657b8d85",
      data: %{
        "foo" => "bar4"
      },
      contenttype: "application/json",
      extensions: %{}
    }

    test_pid = self()

    callback = fn
      body, headers ->
        {:ok, event} = Cloudevents.from_kafka_message(body, headers)
        send(test_pid, event)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(config.client_id, topic, msg, [
      {"content-type", "application/cloudevents+json"}
    ])

    assert_receive received_msg, 10_000
    assert received_msg == expected_msg

    # content-type with charset or any other suffix
    test_produce(config.client_id, topic, msg, [
      {"content-type", "application/cloudevents+json; charset=UTF-8"}
    ])

    assert_receive received_msg, 10_000
    assert received_msg == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :kafka
  test "Consumer should throw an error, when content_type header is set and valid, but not supported" do
    topic = "rig-kafka-test-simple-topic"
    serializer = nil
    schema_registry_host = ""

    config = kafka_config([topic], serializer, schema_registry_host)

    msg =
      Jason.encode!(%{
        "specversion" => "1.0",
        "type" => "com.example.test.simple",
        "source" => "/rig-test",
        "id" => "069711bf-3946-4661-984f-c667657b8d85",
        "data" => %{
          "foo" => "bar"
        }
      })

    test_pid = self()

    callback = fn
      body, headers ->
        {:error, reason} = Cloudevents.from_kafka_message(body, headers)
        send(test_pid, reason)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(config.client_id, topic, msg, [
      {"content-type", "application/cloudevents+xml"}
    ])

    assert_receive received_msg, 10_000
    assert received_msg == {:no_decoder_for_event_format, "xml"}

    RigKafka.Client.stop_supervised(pid)
  end

  # @tag :avro
  # test "Consumer should be able to decode Avro message if content_type header is not set" do
  #   topic = "rig-avro-test-simple-topic"
  #   serializer = "avro"
  #   schema_registry_host = @schema_registry_host

  #   config = kafka_config([topic], serializer, schema_registry_host)

  #   expected_msg = %{
  #     "foo" => "bar"
  #   }

  #   test_pid = self()

  #   callback = fn
  #     body, headers ->
  #       {:ok, event} = Cloudevents.from_kafka_message(body, headers)
  #       send(test_pid, event)
  #       :ok
  #   end

  #   {:ok, pid} = RigKafka.start(config, callback)
  #   :timer.sleep(5_000)

  #   test_produce(
  #     config.client_id,
  #     topic,
  #     Avro.encode("rig-avro-test-simple-topic-value", expected_msg, @schema_registry_host),
  #     []
  #   )

  #   assert_receive received_msg, 10_000
  #   assert received_msg == expected_msg

  #   RigKafka.Client.stop_supervised(pid)
  # end

  @tag :kafka
  test "Consumer should used structured mode if content_type header is not set and message is not Avro encoded" do
    topic = "rig-kafka-test-simple-topic"
    serializer = nil
    schema_registry_host = ""

    config = kafka_config([topic], serializer, schema_registry_host)

    msg =
      Jason.encode!(%{
        "specversion" => "0.2",
        "type" => "com.example.test.simple",
        "source" => "/rig-test",
        "id" => "069711bf-3946-4661-984f-c667657b8d85",
        "data" => %{
          "foo" => "bar5"
        }
      })

    expected_msg = %Cloudevents.Format.V_0_2.Event{
      specversion: "0.2",
      type: "com.example.test.simple",
      source: "/rig-test",
      id: "069711bf-3946-4661-984f-c667657b8d85",
      data: %{
        "foo" => "bar5"
      },
      contenttype: "application/json",
      extensions: %{}
    }

    test_pid = self()

    callback = fn
      body, headers ->
        {:ok, event} = Cloudevents.from_kafka_message(body, headers)
        send(test_pid, event)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(config.client_id, topic, msg, [])

    assert_receive received_msg, 10_000
    assert received_msg == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end
end
