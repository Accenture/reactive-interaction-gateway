defmodule RigKafka.Client do
  @moduledoc """
  The Kafka client that holds connections to one or more brokers.
  """
  require Logger
  @reconnect_timeout_ms 20_000
  use GenServer, shutdown: @reconnect_timeout_ms + 5_000
  use Rig.Config, [:serializer]

  alias RigKafka.Config
  alias RigKafka.Serializer

  @supervisor RigKafka.DynamicSupervisor

  @type callback :: (any -> :ok | any)

  defmodule GroupSubscriber do
    @moduledoc """
    The group subscriber process handles messages from none or many partitions.

    """
    @behaviour :brod_group_subscriber
    require Logger
    require Record
    import Record, only: [defrecord: 2, extract: 2]
    defrecord :kafka_message, extract(:kafka_message, from_lib: "brod/include/brod.hrl")

    @type kafka_headers :: list()

    @impl :brod_group_subscriber
    def init(_brod_group_id, state) do
      {:ok, state}
    end

    # ---

    @spec get_content_type(any()) :: String.t()
    defp get_content_type(<<0::8, _id::32, _body::binary>>), do: "avro/binary"
    defp get_content_type(_), do: "application/json"

    # ---

    @spec get_content_type(kafka_headers) :: map()
    defp remove_prefix(headers) do
      for {k, v} <- headers do
        if String.starts_with?(k, "cloudEvents_") do
          stripped_key =
            k
            |> String.replace_prefix("cloudEvents_", "")
            |> String.to_atom()

          if k == "cloudEvents_rig" do
            {stripped_key, Plug.Conn.Query.decode(v)}
          else
            {stripped_key, v}
          end
        else
          {String.to_atom(k), v}
        end
      end
      |> Enum.into(%{})
    end

    # ---

    @impl :brod_group_subscriber
    def handle_message(topic, partition, message, %{callback: callback} = state) do
      %{offset: offset, value: body, headers: headers} = Enum.into(kafka_message(message), %{})

      headers_no_prefix = remove_prefix(headers)

      ce_specversion =
        case headers_no_prefix do
          %{specversion: version} ->
            version

          %{cloudEventsVersion: version} ->
            version

          _ ->
            headers_no_prefix
        end

      content_type =
        case ce_specversion do
          "0.2" -> Map.get(headers_no_prefix, :contenttype, get_content_type(body))
          "0.1" -> Map.get(headers_no_prefix, :contentType, get_content_type(body))
          _ -> get_content_type(body)
        end

      decoded_body =
        cond do
          content_type == "avro/binary" ->
            data = Jason.decode!(Serializer.decode_body(body, "avro"))
            Map.merge(headers_no_prefix, %{data: data})

          content_type == "application/json" ->
            body

          true ->
            body
        end

      case callback.(decoded_body) do
        :ok ->
          {:ok, :ack, state}

        err ->
          info = %{error: err, topic: topic, partition: partition, offset: offset}
          Logger.error("Callback failed to handle message: #{inspect(info)}")
          {:ok, :ack_no_commit, state}
      end
    end
  end

  # ---

  @spec start_supervised(Config.t(), callback() | nil) :: {:ok, pid} | :ignore | {:error, any}
  def start_supervised(config, callback \\ nil) do
    %{server_id: server_id} = config
    opts = Keyword.merge([config: config, callback: callback], name: server_id)

    DynamicSupervisor.start_child(@supervisor, {__MODULE__, opts})
  end

  # ---

  @spec stop_supervised(pid) :: :ok | {:error, :not_found}
  def stop_supervised(client_pid) do
    DynamicSupervisor.terminate_child(@supervisor, client_pid)
  end

  # ---

  @spec start_link(list) :: {:ok, pid} | :ignore | {:error, any}
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

  def produce(%{server_id: server_id}, topic, schema, key, plaintext)
      when is_binary(topic) and is_binary(key) and is_binary(plaintext) do
    GenServer.call(server_id, {:produce, topic, schema, key, plaintext})
  end

  # ---

  @type kafka_headers :: list()

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

    :brod_client.start_link(brokers, client_id, brod_client_conf)
  end

  # ---

  defp add_ssl_conf(brod_client_conf, nil), do: brod_client_conf

  defp add_ssl_conf(brod_client_conf, config) do
    opts = [
      keyfile: config.path_to_key_pem |> resolve_path,
      certfile: config.path_to_cert_pem |> resolve_path,
      cacertfile: config.path_to_ca_cert_pem |> resolve_path
    ]

    # The Erlang SSL module requires the password to be passed as a charlist:
    opts =
      case config.key_password do
        "" -> opts
        pass -> Keyword.put(opts, :password, String.to_charlist(pass))
      end

    Keyword.put(brod_client_conf, :ssl, opts)
  end

  # ---

  @spec resolve_path(path :: String.t()) :: String.t()
  defp resolve_path(path) do
    working_dir = :code.priv_dir(:rig_outbound_gateway)
    expanded_path = Path.expand(path, working_dir)
    true = File.regular?(expanded_path) || "#{path} is not a file"
    expanded_path
  end

  # ---

  defp add_sasl_conf(brod_client_conf, nil), do: brod_client_conf

  defp add_sasl_conf(brod_client_conf, sasl) do
    if is_nil(brod_client_conf[:ssl]) do
      Logger.warn("SASL is enabled, but SSL is not - credentials are transmitted as cleartext.")
    end

    Keyword.put(brod_client_conf, :sasl, sasl)
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
  def handle_call(
        {:produce, topic, schema, key, plaintext},
        _from,
        %{brod_client: brod_client} = state
      ) do
    result = try_producing_message(brod_client, topic, schema, key, plaintext)
    {:reply, result, state}
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

  @spec add_prefix(map()) :: kafka_headers
  defp add_prefix(headers) do
    for {k, v} <- headers do
      if k == "rig" do
        {"cloudEvents_#{k}", Plug.Conn.Query.encode(v)}
      else
        {"cloudEvents_#{k}", v}
      end
    end
  end

  # ---

  defp try_producing_message(
         brod_client,
         topic,
         schema,
         key,
         plaintext,
         retry_delay_divisor \\ 64
       )

  defp try_producing_message(brod_client, topic, schema, key, plaintext, retry_delay_divisor) do
    {constructed_headers, body} =
      case Jason.decode(plaintext) do
        {:ok, plaintext_map} ->
          %{serializer: serializer} = config()

          case serializer do
            "avro" ->
              {data, headers} = Map.pop(plaintext_map, "data", %{})
              prefixed_headers = add_prefix(headers)

              {prefixed_headers, Serializer.encode_body(data, "avro", schema)}

            _ ->
              constructed_headers =
                case plaintext_map do
                  %{"contenttype" => contenttype} ->
                    [
                      {"cloudEvents_contenttype", contenttype}
                    ]

                  %{"contentType" => contentType} ->
                    [
                      {"cloudEvents_contentType", contentType}
                    ]

                  _ ->
                    []
                end

              {constructed_headers, plaintext}
          end

        {:error, _reason} ->
          {[], plaintext}
      end

    case :brod.produce_sync(
           brod_client,
           topic,
           &compute_kafka_partition/4,
           key,
           %{
             value: body,
             headers: constructed_headers
           }
         ) do
      :ok ->
        :ok

      {:error, :leader_not_available} ->
        try_again? = retry_delay_divisor >= 1

        if try_again? do
          retry_delay_ms = trunc(1_920 / retry_delay_divisor)

          Logger.debug(fn ->
            "Leader not available for Kafka topic #{topic} (retry in #{retry_delay_ms} ms)"
          end)

          :timer.sleep(retry_delay_ms)
          try_producing_message(brod_client, topic, key, body, retry_delay_divisor / 2)
        else
          {:error, :leader_not_available}
        end

      err ->
        err
    end
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
