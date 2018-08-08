defmodule Rig.KafkaTest do
  @moduledoc false
  use Rig.Config, [:topic]
  use ExUnit.Case, async: true

  alias Rig.Kafka, as: SUT

  defmodule ProducerStub do
    @moduledoc false
    def produce_sync(_client, topic, partition_fn, key, value) do
      # let's check that the partition function works while we're here:
      partition_fn.(topic, _n_partitions = 32, key, value)
      :ok
    end
  end

  test "publishing using the stub" do
    assert :ok = SUT.produce("some-topic", "some-key", "some-value", &ProducerStub.produce_sync/5)
  end

  @tag :smoke
  test "publishing using an actual connection" do
    conf = config()
    assert :ok = SUT.produce(conf.topic, "test-key", "test-value")
  end
end
