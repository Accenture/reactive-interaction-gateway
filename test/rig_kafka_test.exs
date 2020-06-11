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

    expected_msg =
      Jason.encode!(%{
        "specversion" => "0.2",
        "type" => "com.example.test.simple",
        "source" => "/rig-test",
        "id" => "069711bf-3946-4661-984f-c667657b8d85",
        "data" => %{
          "foo" => "bar"
        }
      })

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)

    :timer.sleep(5_000)
    RigKafka.produce(config, topic, "", "test", expected_msg)

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
      "foo" => "bar"
    }

    expected_msg = %{
      "specversion" => "0.2",
      "type" => "com.example.test.simple",
      "source" => "/rig-test",
      "id" => "069711bf-3946-4661-984f-c667657b8d85",
      "data" => data
    }

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(config.client_id, topic, Jason.encode!(data), [
      {"content-type", "some-weird-type"},
      {"ce-specversion", "0.2"},
      {"ce-type", "com.example.test.simple"},
      {"ce-source", "/rig-test"},
      {"ce-id", "069711bf-3946-4661-984f-c667657b8d85"}
    ])

    assert_receive received_msg, 10_000
    assert Jason.decode!(received_msg) == expected_msg

    # content-type with uppercase
    test_produce(config.client_id, topic, Jason.encode!(data), [
      {"Content-Type", "some-weird-type"},
      {"ce-specversion", "0.2"},
      {"ce-type", "com.example.test.simple"},
      {"ce-source", "/rig-test"},
      {"ce-id", "069711bf-3946-4661-984f-c667657b8d85"}
    ])

    assert_receive received_msg, 10_000
    assert Jason.decode!(received_msg) == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :avro
  test "Consumer should use binary mode when content_type header is set and valid, but it's Avro" do
    topic = "rig-avro-test-simple-topic"
    serializer = "avro"
    schema_registry_host = @schema_registry_host

    config = kafka_config([topic], serializer, schema_registry_host)

    data = %{
      "foo" => "bar"
    }

    expected_msg = %{
      "specversion" => "0.2",
      "type" => "com.example.test.simple",
      "source" => "/rig-test",
      "id" => "069711bf-3946-4661-984f-c667657b8d85",
      "data" => data
    }

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
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
        {"ce-specversion", "0.2"},
        {"ce-type", "com.example.test.simple"},
        {"ce-source", "/rig-test"},
        {"ce-id", "069711bf-3946-4661-984f-c667657b8d85"}
      ]
    )

    assert_receive received_msg, 10_000
    assert Jason.decode!(received_msg) == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :kafka
  test "Consumer should use structured mode when content_type header is set, valid and JSON" do
    topic = "rig-kafka-test-simple-topic"
    serializer = nil
    schema_registry_host = ""

    config = kafka_config([topic], serializer, schema_registry_host)

    expected_msg = %{
      "specversion" => "0.2",
      "type" => "com.example.test.simple",
      "source" => "/rig-test",
      "id" => "069711bf-3946-4661-984f-c667657b8d85",
      "data" => %{
        "foo" => "bar"
      }
    }

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(config.client_id, topic, Jason.encode!(expected_msg), [
      {"content-type", "application/cloudevents+json"}
    ])

    assert_receive received_msg, 10_000
    assert Jason.decode!(received_msg) == expected_msg

    # content-type with charset or any other suffix
    test_produce(config.client_id, topic, Jason.encode!(expected_msg), [
      {"content-type", "application/cloudevents+json; charset=UTF-8"}
    ])

    assert_receive received_msg, 10_000
    assert Jason.decode!(received_msg) == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :kafka
  test "Consumer should throw an error, when content_type header is set and valid, but not supported" do
    topic = "rig-kafka-test-simple-topic"
    serializer = nil
    schema_registry_host = ""

    config = kafka_config([topic], serializer, schema_registry_host)

    expected_msg = %{
      "specversion" => "0.2",
      "type" => "com.example.test.simple",
      "source" => "/rig-test",
      "id" => "069711bf-3946-4661-984f-c667657b8d85",
      "data" => %{
        "foo" => "bar"
      }
    }

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(config.client_id, topic, Jason.encode!(expected_msg), [
      {"content-type", "application/cloudevents+xml"}
    ])

    assert_receive received_msg, 10_000
    assert received_msg == {:error, {:unknown_content_type, "xml"}}

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :avro
  test "Consumer should be able to decode Avro message if content_type header is not set" do
    topic = "rig-avro-test-simple-topic"
    serializer = "avro"
    schema_registry_host = @schema_registry_host

    config = kafka_config([topic], serializer, schema_registry_host)

    expected_msg = %{
      "foo" => "bar"
    }

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(
      config.client_id,
      topic,
      Avro.encode("rig-avro-test-simple-topic-value", expected_msg, @schema_registry_host),
      []
    )

    assert_receive received_msg, 10_000
    assert Jason.decode!(received_msg) == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end

  @tag :kafka
  test "Consumer should used structured mode if content_type header is not set and message is not Avro encoded" do
    topic = "rig-kafka-test-simple-topic"
    serializer = nil
    schema_registry_host = ""

    config = kafka_config([topic], serializer, schema_registry_host)

    expected_msg = %{
      "specversion" => "0.2",
      "type" => "com.example.test.simple",
      "source" => "/rig-test",
      "id" => "069711bf-3946-4661-984f-c667657b8d85",
      "data" => %{
        "foo" => "bar"
      }
    }

    test_pid = self()

    callback = fn
      msg ->
        send(test_pid, msg)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)
    :timer.sleep(5_000)

    test_produce(config.client_id, topic, Jason.encode!(expected_msg), [])

    assert_receive received_msg, 10_000
    assert Jason.decode!(received_msg) == expected_msg

    RigKafka.Client.stop_supervised(pid)
  end
end
