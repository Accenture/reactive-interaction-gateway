defmodule Rig.KafkaConsumerSetup do
  @moduledoc """
  Boiler plate for initializing a Kafka client from RIG's configuration values.

  ### Callbacks

  Inspect the start-up configuration, make changes, or abort starting the consumer:

      @spec validate(config :: map) :: {:ok, map} | :abort

  React to incoming messages:

      @spec kafka_handler(message :: String.t()) :: :ok | error :: any

  """

  defmacro __using__(additional_config_keys) do
    kafka_config_keys = [
      :brokers,
      :consumer_topics,
      :ssl_enabled?,
      :ssl_ca_certfile,
      :ssl_certfile,
      :ssl_keyfile,
      :ssl_keyfile_pass,
      :sasl
    ]

    config_keys = kafka_config_keys ++ additional_config_keys

    quote do
      require Logger
      use GenServer

      use Rig.Config, unquote(config_keys)

      alias RigKafka

      # ---

      def start_link(opts) do
        conf = config()
        opts = Keyword.merge([name: __MODULE__], opts)

        case validate(config()) do
          {:ok, conf} ->
            do_start_link(conf, opts)

          :abort ->
            Logger.info(fn -> "#{__MODULE__} disabled (configuration)" end)
            :ignore
        end
      end

      # ---

      defp do_start_link(conf, opts) do
        ssl_config =
          if conf.ssl_enabled? do
            %{
              path_to_key_pem: conf.ssl_keyfile,
              key_password: conf.ssl_keyfile_pass,
              path_to_cert_pem: conf.ssl_certfile,
              path_to_ca_cert_pem: conf.ssl_ca_certfile
            }
          else
            nil
          end

        kafka_config =
          RigKafka.Config.new(%{
            brokers: Rig.Config.parse_socket_list(conf.brokers),
            consumer_topics: conf.consumer_topics,
            ssl: ssl_config,
            sasl: parse_sasl_config(conf.sasl)
          })

        case RigKafka.start(kafka_config, &__MODULE__.kafka_handler/1) do
          {:ok, _pid} ->
            Logger.info(fn -> "Kafka connection established for #{__MODULE__}" end)
            GenServer.start_link(__MODULE__, %{kafka_config: kafka_config}, opts)

          :ignore ->
            Logger.info(fn -> "#{__MODULE__} disabled (no Kafka connection created)" end)
            :ignore
        end
      end

      # ---

      @impl GenServer
      def init(state), do: {:ok, state}

      # ---

      @spec parse_sasl_config(String.t() | nil) :: nil | {:plain, String.t(), String.t()}

      defp parse_sasl_config(nil), do: nil

      defp parse_sasl_config("plain:" <> plain) do
        [username | password] = String.split(plain, ":", parts: 2)
        {:plain, username, password}
      end
    end
  end
end
