defmodule RigOutboundGateway.Kafka.MessageHandler do
  @moduledoc """
  Handles messages consumed off a single topic-partition.
  """
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :kafka_message, extract(:kafka_message, from_lib: "brod/include/brod.hrl")

  alias RigOutboundGateway

  alias Poison.Parser, as: JsonParser

  @default_send &RigOutboundGateway.send/1

  @spec message_handler_loop(
          String.t(),
          String.t() | non_neg_integer,
          pid,
          RigOutboundGateway.send_t()
        ) :: no_return
  def message_handler_loop(topic, partition, group_subscriber_pid, send \\ @default_send) do
    common_meta = [
      topic: topic,
      partition: partition
    ]

    receive do
      msg ->
        %{offset: offset, value: body} = Enum.into(kafka_message(msg), %{})
        meta = Keyword.merge(common_meta, body_raw: body, offset: offset)
        ack = fn -> ack_message(group_subscriber_pid, topic, partition, offset) end

        RigOutboundGateway.handle_raw(body, &JsonParser.parse/1, send, ack)
        |> RigOutboundGateway.Logger.log(__MODULE__, meta)

        __MODULE__.message_handler_loop(topic, partition, group_subscriber_pid, send)
    end
  end

  defp ack_message(group_subscriber_pid, topic, partition, offset) do
    # Send the async ack to group subscriber (the offset will be eventually
    # committed to Kafka):
    :brod_group_subscriber.ack(group_subscriber_pid, topic, partition, offset)
  end
end
