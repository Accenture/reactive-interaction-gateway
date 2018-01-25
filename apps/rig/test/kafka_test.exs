defmodule Rig.KafkaTest do
  @moduledoc false
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

  test "publishing" do
    assert :ok = SUT.produce("some-topic", "some-key", "some-value", &ProducerStub.produce_sync/5)
  end
end
