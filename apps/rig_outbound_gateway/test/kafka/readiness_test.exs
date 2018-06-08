defmodule RigOutboundGateway.Kafka.ReadinessTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias RigOutboundGateway.Kafka

  @tag :smoke
  test "kafka consumer connection should be correctly established" do
    assert Kafka.ready?("rig", 0, 10_000)
  end

  @tag :smoke
  test "kafka consumer connection should fail with wrong topic" do
    refute Kafka.ready?("bad", 0, 1_000)
  end

  @tag :smoke
  test "kafka consumer connection should fail with wrong partition" do
    refute Kafka.ready?("rig", 1, 1_000)
  end
end
