defmodule RigOutboundGateway.Kafka.Readiness do
  @moduledoc false
  use Rig.Config, [:brod_client_id]

  alias RigOutboundGateway.Kafka

  @check_delay_ms 1_000

  @spec ready?(Kafka.topic(), Kafka.partition(), timeout_ms :: non_neg_integer()) :: boolean

  def ready?(_topic, _partition, timeout_ms) when timeout_ms < 0, do: false

  def ready?(topic, partition, timeout_ms) do
    %{brod_client_id: brod_client_id} = config()

    connected? = case :brod.get_consumer(brod_client_id, topic, partition) do
      {:ok, _pid} -> true
      _ -> false
    end

    if connected? do
      true
    else
      retry_delay_ms = if timeout_ms >= @check_delay_ms, do: @check_delay_ms, else: timeout_ms
      if retry_delay_ms <= 0 do
        false
      else
        :timer.sleep(retry_delay_ms)
        ready?(topic, partition, timeout_ms - retry_delay_ms)
      end
    end
  end
end
