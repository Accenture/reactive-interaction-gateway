defmodule RigInboundGateway.ApiProxy.BrokerBackend.Kafka do
  @moduledoc """
  Consumes events and forwards them to the event filter by event type.

  """
  use Rig.KafkaConsumerSetup, [:request_topic]

  alias Rig.Connection.Codec

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(message) do
    body = Jason.decode!(message)

    case Map.fetch(body, "correlation_id") do
      {:ok, correlation_id} ->
        {:ok, deserialized_pid} = correlation_id |> Codec.deserialize()
        send(deserialized_pid, {:response_received, message})

      _ ->
        nil
    end

    :ok
  rescue
    err -> {:error, err, message}
  end

  # ---

  def produce(server \\ __MODULE__, key, plaintext) do
    GenServer.call(server, {:produce, key, plaintext})
  end

  # ---

  @impl GenServer
  def handle_call({:produce, key, plaintext}, _from, %{kafka_config: kafka_config} = state) do
    %{request_topic: topic} = config()
    res = RigKafka.produce(kafka_config, topic, key, plaintext)
    {:reply, res, state}
  end
end
