defmodule RigKafka.Client do
  @moduledoc """
  The Kafka client that holds connections to one or more brokers.
  """
  require Logger
  @reconnect_timeout_ms 20_000
  use GenServer, shutdown: @reconnect_timeout_ms + 5_000

  import RigKafka.Types

  alias RigKafka.Config

  @supervisor RigKafka.DynamicSupervisor

  defmodule GroupSubscriber do
    @moduledoc """
    The group subscriber process handles messages from none or many partitions.

    """
    @behaviour :brod_group_subscriber
    require Logger
    require Record
    import Record, only: [defrecord: 2, extract: 2]
    defrecord :kafka_message, extract(:kafka_message, from_lib: "brod/include/brod.hrl")

    @impl :brod_group_subscriber
    def init(_brod_group_id, state) do
      {:ok, state}
    end

    @impl :brod_group_subscriber
    def handle_message(_topic, _partition, message, %{callback: callback} = state) do
      %{offset: _offset, value: body} = Enum.into(kafka_message(message), %{})

      case callback.(body) do
        :ok ->
          {:ok, :ack, state}

        err ->
          Logger.error("Callback failed to handle message: #{inspect(err)}")
          {:ok, :ack_no_commit, state}
      end
    end
  end

  # ---

  def start_supervised(config, callback) do
    %{server_id: server_id} = config
    opts = Keyword.merge([config: config, callback: callback], name: server_id)

    DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
  end

  # ---

  @spec start_link(list) :: {:ok, name :: atom} | :ignore | {:error, any}
  def start_link(opts) do
    config = Keyword.fetch!(opts, :config)

    if Config.valid?(config) do
      state = %{
        config: config,
        callback: Keyword.fetch!(opts, :callback)
      }

      GenServer.start_link(__MODULE__, state, opts)
    else
      Logger.debug(fn -> "Ignoring Kafka connection for #{inspect(config)}" end)
      :ignore
    end
  end

  # ---

  def produce(%{server_id: server_id}, topic, key, plaintext) do
    GenServer.call(server_id, {:produce, topic, key, plaintext})
  end

  # ---

  @impl GenServer
  def init(%{config: config} = args) do
    Process.flag(:trap_exit, true)

    # Always start brod_client as it's needed for producing messages:
    {:ok, brod_client} = start_brod_client(config)

    # Only starts the subscriber in case there are any consumer topics:
    brod_group_subscriber =
      case start_brod_group_subscriber(args) do
        nil -> nil
        {:ok, pid} -> pid
      end

    state =
      Map.merge(args, %{
        brod_client: brod_client,
        brod_group_subscriber: brod_group_subscriber
      })

    {:ok, state}
  end

  # ---

  defp start_brod_client(%{
         brokers: brokers,
         client_id: client_id,
         ssl: ssl,
         sasl: sasl
       }) do
    brod_client_conf =
      [
        endpoints: brokers,
        auto_start_producers: true,
        default_producer_config: []
      ]
      |> add_ssl_conf(ssl)
      |> add_sasl_conf(sasl)

    Logger.debug(fn -> format_client_conf(client_id, brod_client_conf) end)

    :brod_client.start_link(brokers, client_id, brod_client_conf)
  end

  # ---

  defp add_ssl_conf(brod_client_conf, nil), do: brod_client_conf
  defp add_ssl_conf(brod_client_conf, ssl), do: Keyword.put(brod_client_conf, :ssl, ssl)

  # ---

  defp add_sasl_conf(brod_client_conf, nil), do: brod_client_conf

  defp add_sasl_conf(brod_client_conf, sasl) do
    if is_nil(brod_client_conf[:ssl]) do
      Logger.warn("SASL is enabled, but SSL is not - credentials are transmitted as cleartext.")
    end

    Keyword.put(brod_client_conf, :sasl, sasl)
  end

  # ---

  defp format_client_conf(client_id, client_conf) do
    redact_password = fn
      ssl when is_list(ssl) ->
        case ssl[:password] do
          nil -> ssl
          _ -> Keyword.put(ssl, :password, "<REDACTED>")
        end

      no_ssl_config ->
        no_ssl_config
    end

    "Setting up Kafka connection #{client_id}:\n" <>
      (client_conf
       |> Keyword.update(:ssl, nil, redact_password)
       |> inspect(pretty: true))
  end

  # ---

  defp start_brod_group_subscriber(%{config: %{consumer_topics: []}}) do
    nil
  end

  defp start_brod_group_subscriber(%{
         config: %{
           client_id: client_id,
           group_id: group_id,
           consumer_topics: consumer_topics
         },
         callback: callback
       }) do
    group_config = []
    consumer_config = [begin_offset: :latest]

    :brod.start_link_group_subscriber(
      client_id,
      group_id,
      consumer_topics,
      group_config,
      consumer_config,
      _callback_module = GroupSubscriber,
      _callback_init_args = %{callback: callback}
    )
  end

  # ---

  @impl GenServer
  def handle_call({:produce, topic, key, plaintext}, _from, %{brod_client: brod_client} = state) do
    :ok =
      :brod.produce_sync(
        brod_client,
        topic,
        &compute_kafka_partition/4,
        key,
        plaintext
      )

    {:reply, :ok, state}
  end

  # ---

  @impl GenServer
  def handle_info({:EXIT, from, reason}, state) do
    Logger.warn(fn ->
      "RigKafka client caught EXIT from #{inspect(from)} (waiting #{
        div(@reconnect_timeout_ms, 1_000)
      } seconds to reconnect): #{inspect(reason)}"
    end)

    Process.sleep(@reconnect_timeout_ms)
    {:stop, :shutdown, state}
  end

  # ---

  defp compute_kafka_partition(_topic, n_partitions, key, _value) do
    partition =
      key
      |> Murmur.hash_x86_32()
      |> abs
      |> rem(n_partitions)

    {:ok, partition}
  end
end
