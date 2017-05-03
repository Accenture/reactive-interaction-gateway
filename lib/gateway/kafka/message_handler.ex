defmodule Gateway.Kafka.MessageHandler do
  @moduledoc """
  Handles messages consumed off a single topic-partition.
  """
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :kafka_message, extract(:kafka_message, from_lib: "brod/include/brod.hrl")

  alias Gateway.PresenceChannel
  alias Poison.Parser

  @broadcast &Gateway.Endpoint.broadcast/3

  def message_handler_loop(topic, partition, group_subscriber_pid, broadcast \\ @broadcast) do
    receive do
      msg ->
        %{offset: offset, value: value} = Enum.into(kafka_message(msg), %{})
        Logger.info("#{inspect self()} #{topic}-#{partition} Offset: #{offset}, Value: #{value}")
        act_on_message(value, broadcast)
        # Send the async ack to group subscriber (the offset will be eventually
        # committed to Kafka):
        :brod_group_subscriber.ack(group_subscriber_pid, topic, partition, offset)
        __MODULE__.message_handler_loop(topic, partition, group_subscriber_pid, broadcast)
    after
      1000 ->
        __MODULE__.message_handler_loop(topic, partition, group_subscriber_pid, broadcast)
    end
  end

  defp act_on_message(value, broadcast) do
    result =
      with {:ok, parsed} <- Parser.parse(value),
           {:ok, username} <- Map.fetch(parsed, "username")
        do
          broadcast_to_user(username, parsed, broadcast)
          :ok
        end
    if result != :ok do
      Logger.warn("failed to parse incoming message: #{inspect value}")
    end
  end

  defp broadcast_to_user(username, data, broadcast) do
    room = PresenceChannel.room_name(username)
    Logger.debug("will broadcast to #{inspect room}: #{inspect data}")
    broadcast.(
      _topic = room,
      _event = "message",
      _msg = data
    )
  end
end
