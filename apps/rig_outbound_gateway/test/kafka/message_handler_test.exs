defmodule RigOutboundGateway.Kafka.MessageHandlerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias RigOutboundGateway.Kafka.MessageHandler

  describe "the message handler" do
    test "sends message in the order they're received" do
      source_messages = ~w(
        {"username":"fooUser","payload":"one"}
        {"username":"fooUser","payload":"two"}
        {"username":"fooUser","payload":"three"}
        {"username":"fooUser","payload":"four"}
      )

      expected = [
        %{"username" => "fooUser", "payload" => "one"},
        %{"username" => "fooUser", "payload" => "two"},
        %{"username" => "fooUser", "payload" => "three"},
        %{"username" => "fooUser", "payload" => "four"}
      ]

      check(source_messages, expected)
    end

    test "forwards only valid json messages" do
      source_messages = ~w(
        {not-a-valid-json}
        {"this-is":"a-valid-json"}
      )
      expected = [%{"this-is" => "a-valid-json"}]
      # This triggers a warn-level log message as intended, but since its emitted in a
      # spawned process, I don't know how to capture_log it, so it gets printed out :/
      check(source_messages, expected)
    end
  end

  @spec check([String.t(), ...], [map, ...]) :: any
  defp check(source_messages, expected) do
    kafka_topic = "myKafkaTopic"
    partition = "0"
    base_offset = 14
    group_subscriber_pid = self()

    send_stub = Stubr.stub!([send: fn _ -> nil end], call_info: true)

    # run the message handler loop in its own process:
    handler =
      spawn(fn ->
        MessageHandler.message_handler_loop(
          kafka_topic,
          partition,
          group_subscriber_pid,
          &send_stub.send/1
        )
      end)

    # emulate incoming Kafka messages:
    source_messages
    |> Stream.with_index(base_offset)
    |> Enum.each(fn {message_value, offset} ->
         send(handler, create_kafka_message(offset, message_value))
       end)

    # wait until the handler has sent an ack to what it thinks is the group subscriber:
    source_messages
    |> Stream.with_index(base_offset)
    |> Enum.each(fn {_message_value, offset} ->
         assert_receive {:"$gen_cast", {:ack, ^kafka_topic, ^partition, ^offset}}, 200
       end)

    # kill the handler:
    Process.exit(handler, :kill)

    # send should've been called with the messages, in the given order:
    emitted =
      send_stub
      |> Stubr.call_info(:send)
      |> Enum.map(fn %{input: [arg]} -> arg end)

    assert emitted == expected
  end

  defp create_kafka_message(offset, value) do
    {
      :kafka_message,
      offset,
      _magic_byte = 0,
      _attributes = 0,
      _key = "",
      value,
      # -414719538
      _crc = nil,
      # kpro:timestamp_type()
      _timestamp_type = :undefined,
      # int64
      _timestamp = 0
    }
  end
end
