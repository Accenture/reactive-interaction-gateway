defmodule Gateway.Kafka.GroupSubscriber do
  @moduledoc """
  A group subscriber that handles all assignments (i.e., all topic-partitions
  this group subscriber is assigned to by the broker). Incoming messages are
  handled in partition handlers that run in subprocesses (they're spawned in
  `init`).

  Scalability and failover is achieved by:
   - having an even distribution of topic-partitions among the nodes in the
     cluster by means of the Kafka group subscriber protocol;
   - having topic-paritions re-assigned to other group subscribers in the
     cluster automatically whenever this node goes down;
   - periodically committing the offsets to Kafka, so another node will continue
     consuming (almost) at the right offset.

  From brod_group_subscriber:

  A group subscriber is a gen_server which subscribes to partition consumers
  (poller) and calls the user-defined callback functions for message
  processing.

  An overview of what it does behind the scene:
   1. Start a consumer group coordinator to manage the consumer group states,
      @see brod_group_coordinator:start_link/4.
   2. Start (if not already started) topic-consumers (pollers) and subscribe
      to the partition workers when group assignment is received from the
      group leader, @see brod:start_consumer/3.
   3. Call CallbackModule:handle_message/4 when messages are received from
      the partition consumers.
   4. Send acknowledged offsets to group coordinator which will be committed
      to kafka periodically.
  """
  require Logger

  @behaviour :brod_group_subscriber
  @type handlers_t :: %{required(String.t) => nonempty_list(pid)}
  @type state_t :: %{handlers: handlers_t}
  
  @brod_client_id Application.fetch_env!(:gateway, :kafka_client_id)
  @consumer_group_id Application.fetch_env!(:gateway, :kafka_consumer_group_id)
  @topics Application.fetch_env!(:gateway, :kafka_consumed_topics)

  @doc """
  Makes sure the Brod client is running and starts the group subscriber.
  """
  def start_link do
    :brod.start_link_group_subscriber(
      @brod_client_id,
      @consumer_group_id,
      @topics,
      _group_config = [rejoin_delay_seconds: 5],
      _consumer_config = [begin_offset: :earliest],
      _callback_module = __MODULE__,
      _callback_init_args = :no_args
    )
  end

  ## Server callbacks

  @doc """
  brod_group_subscriber callback

  We spawn one message handler for each topic-partition.
  """
  @spec init(String.t, :no_args) :: {:ok, state_t}
  def init(consumer_group_id, :no_args) do
    Logger.info("Starting Kafka group subscriber (group=#{inspect consumer_group_id}, client=#{inspect @brod_client_id}, topics=#{inspect @topics})")
    handlers = spawn_message_handlers(@brod_client_id, @topics)
    {:ok, %{handlers: handlers}}
  end

  @doc """
  brod_group_subscriber callback

  We receive the message here and hand it off to the respective message handler.
  """
  @spec handle_message(String.t, String.t | non_neg_integer, String.t, state_t) :: {:ok, state_t}
  def handle_message(topic, partition, message, state = %{handlers: handlers}) do
    handler_pid = handlers["#{topic}-#{partition}"]
    send(handler_pid, message)
    {:ok, state}
  end

  @spec spawn_message_handlers(String.t, nonempty_list(String.t)) :: handlers_t
  defp spawn_message_handlers(brod_client_id, [topic | remaining_topics]) do
    {:ok, n_partitions} = :brod.get_partitions_count(brod_client_id, topic)
    spawn_for_partition = &spawn_link(
      Gateway.Kafka.MessageHandler,
      :message_handler_loop,
      [topic, _partition = &1, _group_subscriber_pid = self()]
    )
    0..(n_partitions - 1)
    |> Enum.reduce(%{}, fn(partition, acc) ->
      handler_pid = spawn_for_partition.(partition)
      Map.put(acc, "#{topic}-#{partition}", handler_pid)
    end)
    |> Map.merge(spawn_message_handlers(brod_client_id, remaining_topics))
  end
  defp spawn_message_handlers(_brod_client_id, []) do
    %{}
  end

end
