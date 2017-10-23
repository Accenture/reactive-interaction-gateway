defmodule Gateway.Kafka.MessageHandlerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  test "a message should get broadcasted to the right room" do
    assert 1 == check_broadcasts "fooUser", ~w({"username":"fooUser","payload":"ahaoho"})
  end

  test "a non-json message should not be broadcasted" do
    fun = fn ->
      assert 0 == check_broadcasts "nouser", ~w(some-bogus-message)
    end
    assert capture_log(fun) =~ "failed to parse incoming message"
  end

  test "a message without a username field should not be broadcasted" do
    fun = fn ->
      assert 0 == check_broadcasts "nouser", ~w({"payload":"ahaoho"})
    end
    assert capture_log(fun) =~ "failed to parse incoming message"
  end

  test "multiple messages cause multiple broadcasts" do
    assert 4 == check_broadcasts(
      "fooUser",
      ~w(
        {"username":"fooUser","payload":"one"}
        {"username":"fooUser","payload":"two"}
        {"username":"fooUser","payload":"three"}
        {"username":"fooUser","payload":"four"}
      )
    )
  end

  @spec check_broadcasts(String.t, [String.t, ...]) :: boolean()
  defp check_broadcasts(user_id, messages) do
    test_pid = self()
    kafka_topic = "message"
    partition = "0"
    base_offset = 14
    target_room = "user:#{user_id}"

    # the Agent is used to track the broadcasts invoked by the message handler:
    {:ok, broadcast_agent} = Agent.start_link(fn -> %{call_count: 0} end)

    # run the message handler loop in its own process:
    handler = spawn(fn ->
      Gateway.Kafka.MessageHandler.message_handler_loop(
        kafka_topic, partition,
        _group_subscriber_pid = test_pid,
        _broadcast = fn
          (^target_room, ^kafka_topic, %{"username" => ^user_id}) ->
            Agent.update(
              broadcast_agent,
              fn(state) -> Map.update!(state, :call_count, &(&1 + 1)) end
            )
            nil
          (channel_topic, event, message) ->
            raise "unexpected broadcast: channel_topic=#{inspect channel_topic}, event=#{inspect event}, message=#{inspect message}"
        end
      )
    end)

    # emulate incoming Kafka messages:
    messages
    |> Stream.with_index(base_offset)
    |> Enum.each(fn({message_value, offset}) ->
      send(handler, create_kafka_message(offset, message_value))
    end)

    # wait until the handler has sent an ack to what it thinks is the group subscriber:
    messages
    |> Stream.with_index(base_offset)
    |> Enum.each(fn {_message_value, offset} ->
      assert_receive {:"$gen_cast", {:ack, ^kafka_topic, ^partition, ^offset}}, 200
    end)

    # kill the handler:
    Process.exit(handler, :kill)

    # return the number of times the broadcast callback has been invoked and stop the agent:
    n_callback_invocations = Agent.get(broadcast_agent, &(Map.fetch!(&1, :call_count)))
    Agent.stop(broadcast_agent)
    n_callback_invocations
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
