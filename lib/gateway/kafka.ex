defmodule Gateway.Kafka do
  @moduledoc """
  Produce/send Kafka messages.
  """
  require Logger
  alias Gateway.Utils.Jwt
  alias Gateway.ApiProxy.Proxy

  @brod_client_id Application.fetch_env!(:gateway, :kafka_client_id)
  @call_log_topic Application.fetch_env!(:gateway, :kafka_call_log_topic)

  @spec log_proxy_api_call(Proxy.route_map, %Plug.Conn{}) :: Jwt.claim_map
  def log_proxy_api_call(route, conn) do
    claims = extract_claims!(conn)
    username = Map.fetch!(claims, "username")
    message =
      %{
        id: UUID.uuid4(),
        username: username,
        jti: Map.fetch!(claims, "jti"),
        type: "PROXY_API_CALL",
        version: "1.0",
        timestamp: Timex.now |> Timex.to_unix,
        level: 0,
        payload: %{
          service_def: inspect(route),
          request_path: conn.request_path,
          remote_ip: conn.remote_ip |> format_ip,
        },
      }
    message_json = message |> Poison.encode!
    # If topic does not exist, it will be created automatically,
    # provided the server is configured that way. However,
    # this call then returns with {:error, :LeaderNotAvailable},
    # as at that point there won't be a partition leader yet.
    :ok = :brod.produce_sync(
      @brod_client_id,
      @call_log_topic,
      _partition = &compute_kafka_partition/4,
      _key = username,
      _value = message_json
    )
  rescue
    err ->
      test_env? = Application.get_env(:gateway, GatewayWeb.Endpoint, [])[:env] == :test
      if not test_env? do
        Logger.warn("""
        Failed to log API call: #{inspect err}
          route=#{inspect route}
          conn=#{inspect conn}
        """)
      end
  end

  @spec extract_claims!(%Plug.Conn{}) :: Jwt.claim_map
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

  @spec format_ip({integer, integer, integer, integer}) :: String.t
  defp format_ip(ip_tuple) do
    ip_tuple
    |> Tuple.to_list
    |> Enum.map(&Integer.to_string/1)
    |> Enum.join(".")
  end

  defp compute_kafka_partition(_topic, n_partitions, key, _value) do
    partition =
      key
      |> Murmur.hash_x86_32
      |> abs
      |> rem(n_partitions)
    {:ok, partition}
  end
end
