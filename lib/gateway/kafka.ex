defmodule Gateway.Kafka do
  @moduledoc """
  Produce/send Kafka messages.

  ## About the Kafka Integration
  In order to scale horizontally, [Kafka Consumer
  Groups](https://kafka.apache.org/documentation/#distributionimpl) are used.
  [Brod](https://github.com/klarna/brod), which is the library used for communicating
  with Kafka, has its client supervised by `Gateway.Kafka.Sup`, which also takes care
  of the group subscriber. It uses delays between restarts, in order to delay
  reconnects in the case of connection errors.
  
  `Gateway.Kafka.Sup` is itself supervised by `Gateway.Kafka.SupWrapper`. The
  wrapper's sole purpose is to allow the application to come up even if there is not a
  single broker online. Without it, the failure to connect to any broker would
  propagate all the way to the Phoenix application, bringing it down in the process.
  Having the wrapper makes the application startup more reliable.
  
  The consumer setup is done in `Gateway.Kafka.GroupSubscriber`; take a look at its
  moduledoc for more information. Finally, `Gateway.Kafka.MessageHandler` hosts the
  code for the actual processing of incoming messages.

  """
  use Gateway.Config, [:brod_client_id, :log_topic]
  require Logger
  alias Gateway.Utils.Jwt
  alias Gateway.ApiProxy.Proxy

  @doc """
  Log proxied API calls to Kafka.

  Among other data, the log message includes the payload, the JWT jti and the current
  timestamp. Messages are produced to the Kafka broker synchronously.
  """
  @type producer_sync_t :: (any, any, any, any, any -> :ok | {:error, any})
  @spec log_proxy_api_call(Proxy.route_map, %Plug.Conn{}, producer_sync_t) :: :ok | {:error, any}
  def log_proxy_api_call(route, conn, produce_sync \\ &:brod.produce_sync/5) do
    claims = extract_claims!(conn)
    username = Map.fetch!(claims, "username")
    jti =
      case Map.get(claims, "jti") do
        nil ->
          Logger.warn("jti not found in claims (#{inspect claims})")
          nil
        jti -> jti
      end
    message =
      %{
        id: UUID.uuid4(),
        username: username,
        jti: jti,
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
    # If topic does not exist, it will be created automatically, provided the server is
    # configured that way. However, this call then returns with {:error, # :LeaderNotAvailable},
    # as at that point there won't be a partition leader yet.
    conf = config()
    :ok = produce_sync.(
      conf.brod_client_id,
      conf.log_topic,
      _partition = &compute_kafka_partition/4,
      _key = username,
      _value = message_json
    )
  rescue
    err ->
      case err do
        %KeyError{key: "username", term: claims} ->
          Logger.warn("""
          A username is required for publishing to the right Kafka topic, \
          but no such field is found in the given claims: #{inspect claims}
          """)
        _ ->
          Logger.error("""
          Failed to log API call: #{inspect err}
            ROUTE=#{inspect route}
            CONN=#{inspect conn}
          """)
      end
      {:error, err}
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
