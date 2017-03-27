defmodule Gateway.Kafka.MessageHandler do
  @moduledoc """
  Handles messages consumed off a single topic-partition.
  """
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :kafka_message, extract(:kafka_message, from_lib: "brod/include/brod.hrl")

  def message_handler_loop(topic, partition, group_subscriber_pid) do
    receive do
      msg ->
        %{offset: offset, value: value} = Enum.into(kafka_message(msg), %{})
        Logger.info("#{inspect self()} #{topic}-#{partition} Offset: #{offset}, Value: #{value}")
        # Send the async ack to group subscriber (the offset will be eventually
        # committed to Kafka):
        :brod_group_subscriber.ack(group_subscriber_pid, topic, partition, offset)
        __MODULE__.message_handler_loop(topic, partition, group_subscriber_pid)
    after
      1000 ->
        __MODULE__.message_handler_loop(topic, partition, group_subscriber_pid)
    end
  end
end
