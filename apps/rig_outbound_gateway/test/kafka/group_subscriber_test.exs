defmodule RigOutboundGateway.Kafka.GroupSubscriberTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias RigOutboundGateway.Kafka.GroupSubscriber

  @tag :smoke
  test "kafka consumer connection should be correctly established" do
    assert GroupSubscriber.wait_for_consumer_ready("rig", 0) == {
      :ok,
      "Consumer for topic: rig and partition: 0 is ready."
    }
  end

  @tag :smoke
  test "kafka consumer connection should fail with wrong topic" do
    assert GroupSubscriber.wait_for_consumer_ready("bad", 0, 5000) == {
      :error,
      "Consumer ready check for topic: bad and partition: 0 timed out."
    }
  end

  @tag :smoke
  test "kafka consumer connection should fail with wrong partition" do
    assert GroupSubscriber.wait_for_consumer_ready("rig", 1, 5000) == {
      :error,
      "Consumer ready check for topic: rig and partition: 1 timed out."
    }
  end
end
