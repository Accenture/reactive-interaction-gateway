defmodule RigInboundGateway.ApiProxy.Handler.Kafka do
  @moduledoc """
  Handles requests for Kafka targets.

  """
  use Rig.KafkaConsumerSetup, [:cors, :request_topic, :response_timeout]

  alias Plug.Conn

  alias RigInboundGateway.ApiProxy.Handler
  @behaviour Handler

  alias Rig.Connection.Codec

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(message) do
    with {:ok, body} <- Jason.decode(message),
         {:ok, rig_metadata} <- Map.fetch(body, "rig"),
         {:ok, correlation_id} <- Map.fetch(rig_metadata, "correlationID"),
         {:ok, deserialized_pid} <- Codec.deserialize(correlation_id) do
      Logger.debug(fn ->
        "HTTP response via Kafka to #{inspect(deserialized_pid)}: #{inspect(message)}"
      end)

      send(deserialized_pid, {:response_received, message})
    else
      err ->
        Logger.warn(fn -> "Parse error #{inspect(err)} for #{inspect(message)}" end)
        :ignore
    end

    :ok
  rescue
    err -> {:error, err, message}
  end

  # ---

  @impl Handler
  def handle_http_request(conn, api, endpoint)

  @doc "CORS response for preflight request."
  def handle_http_request(%{method: "OPTIONS"} = conn, _, %{"target" => "kafka"}) do
    conn
    |> with_cors()
    |> Conn.send_resp(:no_content, "")
  end

  @doc "Produce request to Kafka topic and optionally wait for response."
  def handle_http_request(conn, _, %{"target" => "kafka"} = endpoint) do
    %{params: %{"partition_key" => partition_key, "data" => data}} = conn

    kafka_message =
      data
      |> Map.put("rig", %{
        correlationID: Codec.serialize(self()),
        host: conn.host,
        method: conn.method,
        requestPath: conn.request_path,
        port: conn.port,
        remoteIP: to_string(:inet_parse.ntoa(conn.remote_ip)),
        reqHeaders: Enum.map(conn.req_headers, &Tuple.to_list(&1)),
        scheme: conn.scheme,
        queryString: conn.query_string
      })
      |> Poison.encode!()

    produce(
      _partition_key = partition_key,
      _plaintext = kafka_message
    )

    wait_for_response? =
      case Map.get(endpoint, "response_from") do
        "kafka" -> true
        _ -> false
      end

    if wait_for_response? do
      wait_for_response(conn)
    else
      Conn.send_resp(conn, :accepted, "Accepted.")
    end
  end

  # ---

  defp wait_for_response(conn) do
    conf = config()

    receive do
      {:response_received, response} ->
        conn
        |> with_cors()
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(:ok, response)
    after
      conf.response_timeout ->
        conn
        |> with_cors()
        |> Conn.send_resp(:gateway_timeout, "")
    end
  end

  # ---

  defp produce(server \\ __MODULE__, key, plaintext) do
    GenServer.call(server, {:produce, key, plaintext})
  end

  # ---

  @impl GenServer
  def handle_call({:produce, key, plaintext}, _from, %{kafka_config: kafka_config} = state) do
    %{request_topic: topic} = config()
    res = RigKafka.produce(kafka_config, topic, key, plaintext)
    {:reply, res, state}
  end

  # ---

  defp with_cors(conn) do
    conn
    |> Conn.put_resp_header("access-control-allow-origin", config().cors)
    |> Conn.put_resp_header("access-control-allow-methods", "*")
    |> Conn.put_resp_header("access-control-allow-headers", "content-type,authorization")
  end
end
