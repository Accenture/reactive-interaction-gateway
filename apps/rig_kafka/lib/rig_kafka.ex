defmodule RigKafka do
  @moduledoc """
  Kafka client for RIG.

  Basically wrapping :brod, tailored to our needs.

  """
  alias RigKafka.Client
  alias RigKafka.Config

  @spec start(Config.t(), Client.callback() | nil) :: {:ok, pid} | :ignore | {:error, any}
  defdelegate start(config, callback \\ nil), to: RigKafka.Client, as: :start_supervised

  @spec produce(Config.t(), String.t(), String.t(), String.t(), String.t()) :: :ok
  defdelegate produce(config, topic, schema, key, plaintext), to: RigKafka.Client
end
