defmodule RigKafka.Config do
  @moduledoc """
  Kafka connection configuration.
  """
  @type broker :: {
          host :: String.t(),
          port :: pos_integer()
        }

  @type topic :: String.t()

  @type ssl_config :: %{
          path_to_key_pem: String.t(),
          key_password: String.t(),
          path_to_cert_pem: String.t(),
          path_to_ca_cert_pem: String.t()
        }

  @type sasl_config :: {
          :plain,
          username :: String.t(),
          password :: String.t()
        }

  @type t :: %{
          brokers: [broker],
          consumer_topics: [topic],
          server_id: atom,
          client_id: atom,
          group_id: String.t(),
          ssl: nil | ssl_config,
          sasl: nil | sasl_config
        }

  @enforce_keys [:brokers, :consumer_topics, :client_id, :group_id]
  defstruct brokers: [],
            consumer_topics: [],
            server_id: nil,
            client_id: nil,
            group_id: nil,
            ssl: nil,
            sasl: nil

  def new(config) do
    uuid = UUID.uuid4()

    %__MODULE__{
      brokers: Map.get(config, :brokers, []),
      consumer_topics: Map.get(config, :consumer_topics, []),
      server_id: Map.get(config, :server_id) || String.to_atom("rig_kafka_#{uuid}"),
      client_id: Map.get(config, :client_id) || String.to_atom("brod_client_#{uuid}"),
      group_id: Map.get(config, :group_id) || "brod_group_#{uuid}",
      ssl: Map.get(config, :ssl),
      sasl: Map.get(config, :sasl)
    }
  end

  def valid?(%{brokers: brokers}) do
    # TODO we could do a lot more here
    length(brokers) > 0
  end
end
