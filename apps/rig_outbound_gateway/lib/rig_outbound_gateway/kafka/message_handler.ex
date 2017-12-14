defmodule RigOutboundGateway.Kafka.MessageHandler do
  @moduledoc """
  Handles messages consumed off a single topic-partition.
  """
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :kafka_message, extract(:kafka_message, from_lib: "brod/include/brod.hrl")

  alias RigOutboundGateway
  alias Poison.Parser

  @default_send &RigOutboundGateway.send/1

  @spec message_handler_loop(
          String.t(),
          String.t() | non_neg_integer,
          pid,
          RigOutboundGateway.send_t()
        ) :: no_return
  def message_handler_loop(topic, partition, group_subscriber_pid, send \\ @default_send) do
    receive do
      msg ->
        %{offset: offset, value: value} = Enum.into(kafka_message(msg), %{})

        case Parser.parse(value) do
          {:ok, payload} ->
            send.(payload)
            log_success_message(payload, topic, partition, offset)

          err ->
            log_error_message(err, value, topic, partition, offset)
        end

        # Send the async ack to group subscriber (the offset will be eventually
        # committed to Kafka):
        :brod_group_subscriber.ack(group_subscriber_pid, topic, partition, offset)
        __MODULE__.message_handler_loop(topic, partition, group_subscriber_pid, send)
    after
      1000 ->
        __MODULE__.message_handler_loop(topic, partition, group_subscriber_pid, send)
    end
  end

  defp log_success_message(message, topic, partition, offset) do
    Logger.debug(fn ->
      message_length = String.length(message)
      message = format_message(message, 200)

      "#{inspect(self())} #{topic}-#{partition} Offset:#{offset} Len:#{message_length} Val:#{
        message
      }"
    end)
  end

  defp log_error_message(err, non_json, topic, partition, offset) do
    Logger.warn(fn ->
      length = String.length(non_json)
      non_json = format_message(non_json, 200)

      "#{inspect(self())} PARSE_ERROR:#{inspect err} #{topic}-#{partition} Offset:#{offset} Len:#{length} Val:#{non_json}"
    end)
  end

  defp format_message(message, print_length) do
    message_length = String.length(message)

    if message_length < print_length do
      message
    else
      String.slice(message, 0..(print_length - 2)) <> ".."
    end
  end
end
