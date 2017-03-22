defmodule Gateway.Kafka.MessageHandlerTest do
  use ExUnit.Case, async: true

  test "a message should get broadcasted to the right room" do
    assert 1 == broadcast? "fooUser", ~s({"username":"fooUser","payload":"ahaoho"})
  end

  test "a non-json message should not be broadcasted" do
    assert 0 == broadcast? "", ~s(some bogus message)
  end

  test "a message without a username field should not be broadcasted" do
    assert 0 == broadcast? "", ~s({"payload":"ahaoho"})
  end

  defp broadcast?(user_id, message_value) do
    test_pid = self()
    topic = "message"
    partition = "0"
    offset = 14
    target_room = "presence:#{user_id}"

    # the Agent is used to track the broadcasts invoked by the message handler:
    {:ok, broadcast_agent} = Agent.start_link fn -> %{call_count: 0} end

    # run the message handler loop in its own process:
    handler = spawn_link fn ->
      Gateway.Kafka.MessageHandler.message_handler_loop(
        topic, partition,
        _group_subscriber_pid = test_pid,
        _broadcast = fn
          ^target_room, "kafka_message", %{"username" => ^user_id} ->
            Agent.update(
              broadcast_agent,
              fn state -> Map.update!(state, :call_count, &(&1 + 1)) end
            )
            nil
          topic, event, message ->
            raise "unexpected broadcast: topic=#{inspect topic}, event=#{inspect event}, message=#{inspect message}"
        end
      )
    end

    # emulate an incoming Kafka message:
    send handler, create_kafka_message(offset, message_value)

    # wait until the handler has sent an ack to was it thinks is the group subscriber:
    assert_receive {:"$gen_cast", {:ack, ^topic, ^partition, ^offset}}

    # returns the number of times the broadcast callback has been invoked:
    Agent.get broadcast_agent, &Map.fetch!(&1, :call_count)
  end

  defp create_kafka_message(offset, value) do
    {
      :kafka_message,
      offset,
      _magic_byte = 0,
      _attributes = 0,
      _key = "",
      value,
      _crc = nil  # -414719538
    }
  end
end
