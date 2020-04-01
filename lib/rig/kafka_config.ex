defmodule Rig.KafkaConfig do
  @moduledoc """
  Boiler plate for initializing Kafka client configuration.
  """

  alias RigKafka

  # ---

  @doc """
  Create a Kafka configuration map from given parameters.

  Note that `brokers` is the only required parameter.

  # Example

      iex> __MODULE__.parse(%{brokers: ["localhost:9092"]})
      %RigKafka.Config{
        brokers: [{"localhost", 9092}],
        client_id: :"brod_client_cc25589c-4180-4f5d-93bf-b4fa778892b4",
        consumer_topics: [],
        group_id: nil,
        sasl: nil,
        schema_registry_host: nil,
        serializer: nil,
        server_id: :"rig_kafka_cc25589c-4180-4f5d-93bf-b4fa778892b4",
        ssl: nil
      }
  """
  def parse(conf) do
    ssl_config =
      if conf[:ssl_enabled?] do
        %{
          path_to_key_pem: conf.ssl_keyfile,
          key_password: conf.ssl_keyfile_pass,
          path_to_cert_pem: conf.ssl_certfile,
          path_to_ca_cert_pem: conf.ssl_ca_certfile
        }
      else
        nil
      end

    conf
    |> Map.put(:brokers, Rig.Config.parse_socket_list(conf.brokers))
    |> Map.put(:serializer, conf[:serializer])
    |> Map.put(:schema_registry_host, conf[:schema_registry_host])
    |> Map.put(:ssl, ssl_config)
    |> Map.put(:sasl, parse_sasl_config(conf[:sasl]))
    |> RigKafka.Config.new()
  end

  # ---

  @spec parse_sasl_config(String.t() | nil) :: nil | {:plain, String.t(), String.t()}

  defp parse_sasl_config(nil), do: nil

  defp parse_sasl_config("plain:" <> plain) do
    [username, password] = String.split(plain, ":", parts: 2)
    {:plain, username, password}
  end

  defp parse_sasl_config("gssapi:" <> gssapi) do
    [keytab, principal] = String.split(gssapi, ":", parts: 2)
    {:callback, :brod_gssapi, {:gssapi, keytab, principal}}
  end
end
