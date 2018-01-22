defmodule Rig.Kafka do
  @moduledoc """
  Producing messages to Kafka topics.

  """
  use Rig.Config, [:enabled?, :brod_client_id]

  def produce(topic, key, plaintext, produce_fn \\ &:brod.produce_sync/5) do
    conf = config()
    if conf.enabled? do
      do_produce(topic, key, plaintext, produce_fn)
    end
  end

  defp do_produce(topic, key, plaintext, produce_fn) do
    conf = config()

    :ok =
      produce_fn.(
        conf.brod_client_id,
        topic,
        _partition = &compute_kafka_partition/4,
        key,
        _value = plaintext
      )
  end

  defp compute_kafka_partition(_topic, n_partitions, key, _value) do
    partition =
      key
      |> Murmur.hash_x86_32()
      |> abs
      |> rem(n_partitions)

    {:ok, partition}
  end
end
