defmodule Rig.KafkaConfig do
  @moduledoc """
  Boiler plate for initializing Kafka client configuration.
  """

  alias RigKafka

  # ---

  def parse(conf) do
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

    conf
    |> Map.put(:brokers, Rig.Config.parse_socket_list(conf.brokers))
    |> Map.put(:ssl, ssl_config)
    |> Map.put(:sasl, parse_sasl_config(conf.sasl))
    |> RigKafka.Config.new()
  end

  # ---

  @spec parse_sasl_config(String.t() | nil) :: nil | {:plain, String.t(), String.t()}

  defp parse_sasl_config(nil), do: nil

  defp parse_sasl_config("plain:" <> plain) do
    [username | password] = String.split(plain, ":", parts: 2)
    {:plain, username, password}
  end
end
