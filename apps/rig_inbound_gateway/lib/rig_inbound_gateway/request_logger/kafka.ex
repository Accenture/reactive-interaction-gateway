defmodule RigInboundGateway.RequestLogger.Kafka do
  @moduledoc """
  Kafka request logger implementation.

  """
  use Rig.Config, [:log_topic]
  require Logger
  alias Rig.Kafka, as: RigKafka
  alias RigAuth.Jwt.Utils, as: Jwt
  alias UUID

  @behaviour RigInboundGateway.RequestLogger

  @impl RigInboundGateway.RequestLogger
  @spec log_call(Proxy.endpoint(), Proxy.api_definition(), %Plug.Conn{}) :: :ok
  def log_call(
        %{"not_secured" => false} = endpoint,
        %{"auth_type" => "jwt"} = api_definition,
        conn
      ) do
    claims = extract_claims!(conn)
    username = Map.fetch!(claims, "username")

    jti =
      case Map.get(claims, "jti") do
        nil ->
          Logger.warn("jti not found in claims (#{inspect(claims)})")
          nil

        jti ->
          jti
      end

    event = %{
      "username" => username,
      "jti" => jti,
      "endpoint" => inspect(endpoint),
      "apiDefinition" => inspect(api_definition),
      "requestPath" => conn.request_path,
      "remoteIP" => conn.remote_ip |> format_ip
    }

    # See https://github.com/cloudevents/spec/blob/v0.1/spec.md
    cloud_event = %{
      "cloudEventsVersion" => "0.1",
      "eventType" => "com.accenture.rig.inboundRequest",
      "eventTypeVersion" => "1.0",
      "source" => "rig",
      "eventID" => UUID.uuid4(),
      "eventTime" => Timex.now() |> Timex.format!("{ISO:Extended:Z}"),
      "contentType" => "application/json",
      "data" => Poison.encode!(event)
    }

    # If topic does not exist, it will be created automatically, provided the server is
    # configured that way. Nevertheless, in that case this call returns
    # {:error, :LeaderNotAvailable} (there won't be a partition leader yet).
    conf = config()
    RigKafka.produce(conf.log_topic, _key = username, _plaintext = Poison.encode!(cloud_event))
  rescue
    err ->
      case err do
        %KeyError{key: "username", term: claims} ->
          Logger.warn("""
          A username is required for publishing to the right Kafka topic, \
          but no such field is found in the given claims: #{inspect(claims)}
          """)

        _ ->
          Logger.error("""
          Failed to log API call: #{inspect(err)}
            endpoint=#{inspect(endpoint)}
            api_definition=#{inspect(api_definition)}
          """)
      end

      {:error, err}
  end

  def log_call(_endpoint, _api_definition, _conn) do
    # Unauthenticated calls are not sent to Kafka.
    :ok
  end

  @spec extract_claims!(%Plug.Conn{}) :: Jwt.claim_map()
  defp extract_claims!(conn) do
    # we assume there is exactly one valid token:
    [token] =
      conn
      |> Plug.Conn.get_req_header("authorization")
      |> Stream.filter(&Jwt.valid?/1)
      |> Enum.take(1)

    {:ok, claims} = Jwt.decode(token)
    claims
  end

  @spec format_ip({integer, integer, integer, integer}) :: String.t()
  defp format_ip(ip_tuple) do
    ip_tuple
    |> Tuple.to_list()
    |> Enum.map(&Integer.to_string/1)
    |> Enum.join(".")
  end
end
