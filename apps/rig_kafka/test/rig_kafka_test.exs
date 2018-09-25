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

  describe "Starting a new RigKafka client" do
    test "succeeds when given a valid config." do
      # There are no clients:
      assert %{active: 0} = DynamicSupervisor.count_children(@sup)

      # Start a new client using valid config:
      config = Config.new(%{brokers: [{"localhost", 9092}], consumer_topics: ["rig"]})
      dummy_callback = fn _ -> :ok end
      {:ok, pid} = RigKafka.start(config, dummy_callback)

      # Now there's one client (even though the connection is probably down):
      assert %{active: 1} = DynamicSupervisor.count_children(@sup)

      DynamicSupervisor.terminate_child(@sup, pid)
    end
  end

  @tag :smoke
  describe "Given a started RigKafka client," do
    test "messages can be produced and consumed." do
      topic = "rig"

      config = Config.new(%{brokers: [{"localhost", 9092}], consumer_topics: [topic]})

      expected_msg = "this is a test message"
      test_pid = self()

      callback = fn
        ^expected_msg ->
          send(test_pid, :test_message_received)
          :ok
      end

      {:ok, pid} = RigKafka.start(config, callback)

      Process.sleep(1_000)
      RigKafka.produce(config, topic, "test", expected_msg)

      assert_receive :test_message_received

      DynamicSupervisor.terminate_child(@sup, pid)
    end
  end
end
