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
  alias RigKafka.Config

  @sup RigKafka.DynamicSupervisor

  defp kafka_config(consumer_topics) do
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
      group_id: "rig"
    })
  end

  @tag :kafka
  test "Given a started RigKafka client, messages can be produced and consumed." do
    topic = "rig_kafka_test_simple_topic"

    config = kafka_config([topic])

    expected_msg = "this is a test message"
    test_pid = self()

    callback = fn
      ^expected_msg ->
        send(test_pid, :test_message_received)
        :ok
    end

    {:ok, pid} = RigKafka.start(config, callback)

    RigKafka.produce(config, topic, "test", expected_msg)

    assert_receive :test_message_received, 10_000

    RigKafka.produce(config, topic, "test", expected_msg)
    assert_receive :test_message_received, 10_000

    DynamicSupervisor.terminate_child(@sup, pid)
  end
end
