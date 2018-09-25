defmodule RigKafka do
  alias RigKafka.Types

  # @spec start(Types.name(), Types.brokers(), Types.topics(), Types.callback()) :: {:ok, pid}
  defdelegate start(config, callback), to: RigKafka.Client, as: :start_supervised

  defdelegate produce(config, topic, key, plaintext), to: RigKafka.Client

  # defdelegate ready?(pid, topic, partition, timeout \\ 0), to: RigKafka.Readiness
end
