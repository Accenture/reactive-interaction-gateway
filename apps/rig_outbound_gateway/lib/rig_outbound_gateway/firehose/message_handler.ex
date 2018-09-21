defmodule RigOutboundGateway.Firehose.MessageHandler do
  @moduledoc """
  Handles messages consumed off a single topic-partition.
  """
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :kafka_message, extract(:kafka_message, from_lib: "brod/include/brod.hrl")

  alias RigOutboundGateway

  @default_send &RigOutboundGateway.send/1

  @spec message_handler_loop(
          String.t(),
          String.t() | non_neg_integer,
          pid,
          String.t(),
          RigOutboundGateway.send_t()
        ) :: no_return
  def message_handler_loop(topic, partition, group_subscriber_pid, targets, send \\ @default_send) do
    receive do
      msg ->
        %{offset: offset, value: body} = Enum.into(kafka_message(msg), %{})

        parsed_body = Poison.encode!(body)
        Enum.each(targets, fn(target) -> HTTPoison.post(target, parsed_body) end)
        Logger.debug("Event sent to HTTP endpoint")

        ack_message(group_subscriber_pid, topic, partition, offset)
        __MODULE__.message_handler_loop(topic, partition, group_subscriber_pid, send)
    end
  end

  defp ack_message(group_subscriber_pid, topic, partition, offset) do
    # Send the async ack to group subscriber (the offset will be eventually
    # committed to Kafka):
    :brod_group_subscriber.ack(group_subscriber_pid, topic, partition, offset)
  end
end
