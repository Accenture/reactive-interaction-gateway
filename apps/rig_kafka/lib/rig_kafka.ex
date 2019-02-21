defmodule RigKafka do
  @moduledoc """
  Kafka client for RIG.

  Basically wrapping :brod, tailored to our needs.

  """
  alias RigKafka.Client
  alias RigKafka.Config

  @typep topic :: String.t()
  @typep schema :: String.t()
  @typep key :: String.t()
  @typep plaintext :: String.t()

  @spec start(Config.t(), Client.callback() | nil) :: {:ok, pid} | :ignore | {:error, any}
  defdelegate start(config, callback \\ nil), to: RigKafka.Client, as: :start_supervised

  @spec produce(Config.t(), topic, schema, key, plaintext) :: :ok
  defdelegate produce(config, topic, schema, key, plaintext), to: RigKafka.Client
end
