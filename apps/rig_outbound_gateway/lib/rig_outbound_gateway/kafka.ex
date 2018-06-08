defmodule RigOutboundGateway.Kafka do
  @moduledoc """
  Interface to Kafka-related functionality.
  """

  @type topic :: String.t()
  @type partition :: non_neg_integer()

  defdelegate ready?(topic, partition, timeout \\ 0), to: RigOutboundGateway.Kafka.Readiness
end
