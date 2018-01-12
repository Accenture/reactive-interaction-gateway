defmodule Rig.Kafka do
  @moduledoc """
  Producing messages to Kafka topics.

  """
  use Rig.Config, [:enabled?, :brod_client_id, :produce_fn]

  def produce(topic, key, plaintext) do
    conf = config()
    if conf.enabled? do
      do_produce(topic, key, plaintext)
    end
  end

  defp do_produce(topic, key, plaintext) do
    conf = config()

    :ok =
      conf.produce_fn.(
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
