defmodule RigInboundGateway.RequestLogger.Kafka do
  @moduledoc """
  Kafka request logger implementation.
  """
  use Rig.KafkaConsumerSetup, [:log_topic, :log_schema, :serializer]

  alias RigInboundGateway.RequestLogger
  alias RigTracing.TracePlug
  @behaviour RequestLogger
  alias UUID

  require Logger

  # ---

  @spec kafka_handler(any()) ::
          :ok
          | {:error, %{:__exception__ => true, :__struct__ => atom(), optional(atom()) => any()},
             any()}
  def kafka_handler(_message), do: :ok

  # ---

  @spec validate(any()) :: {:ok, any()}
  def validate(conf), do: {:ok, conf}

  @spec log_call(Proxy.endpoint(), Proxy.api_definition(), %Plug.Conn{}) :: :ok
  @impl RequestLogger
  def log_call(
        endpoint,
        _api_definition,
        conn
      ) do
    %{
      serializer: serializer
    } = config()

    contenttype =
      case serializer do
        "avro" -> "avro/binary"
        _ -> "application/json"
      end

    kafka_message =
      %{
        id: UUID.uuid4(),
        time: Timex.now() |> Timex.format!("{RFC3339}"),
        source: "/rig",
        type: "com.rig.proxy.api.call",
        contenttype: contenttype,
        specversion: "0.2",
        data: %{
          endpoint: endpoint,
          request_path: conn.request_path,
          remote_ip: conn.remote_ip |> format_ip
        }
      }
      |> TracePlug.append_distributed_tracing_context(TracePlug.tracecontext_headers())
      |> Poison.encode!()

    produce("partition", kafka_message)
  end

  # ---

  defp produce(server \\ __MODULE__, key, plaintext) do
    GenServer.cast(server, {:produce, key, plaintext})
  end

  # ---

  @impl GenServer
  def handle_cast({:produce, key, plaintext}, %{kafka_config: kafka_config} = state) do
    %{log_topic: topic, log_schema: schema} = config()
    RigKafka.produce(kafka_config, topic, schema, key, plaintext)
    {:noreply, state}
  end

  # ---

  @spec format_ip({integer, integer, integer, integer}) :: String.t()
  defp format_ip(ip_tuple) do
    ip_tuple
    |> Tuple.to_list()
    |> Enum.map(&Integer.to_string/1)
    |> Enum.join(".")
  end
end
