defmodule Gateway.Kafka.MessageHandler do
  @moduledoc """
  Handles messages consumed off a single topic-partition.
  """
  use Gateway.Config, [:message_user_field, :target_channel_from_user]
  require Logger
  require Record
  import Record, only: [defrecord: 2, extract: 2]
  defrecord :kafka_message, extract(:kafka_message, from_lib: "brod/include/brod.hrl")

  alias Poison.Parser

  @broadcast &GatewayWeb.Endpoint.broadcast/3
  @type broadcast_t :: (String.t, String.t, String.t -> any)

  @spec message_handler_loop(String.t, String.t | non_neg_integer, pid, broadcast_t) :: no_return
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

  @spec act_on_message(String.t, broadcast_t) :: any
  defp act_on_message(value, broadcast) do
    conf = config()
    with {:ok, parsed} <- Parser.parse(value),
         {:ok, username} <- Map.fetch(parsed, conf.message_user_field) do
      broadcast_to_user(username, parsed, broadcast)
    else
      err -> Logger.warn("failed to parse incoming message: #{inspect value}: #{inspect err}")
    end
  end

  @spec broadcast_to_user(String.t, %{optional(any) => any}, broadcast_t) :: any
  defp broadcast_to_user(username, data, broadcast) do
    room = config().target_channel_from_user.(username)
    Logger.debug("will broadcast to #{inspect room}: #{inspect data}")
    broadcast.(
      _topic = room,
      _event = "message",
      _msg = data
    )
  end
end
