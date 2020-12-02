defmodule RigInboundGateway.ApiProxy.Handler.Kafka do
  @moduledoc """
  Handles requests for Kafka targets.

  """
  use Rig.KafkaConsumerSetup, [:cors, :response_timeout]

  alias Plug.Conn
  alias Rig.Connection.Codec
  alias RIG.Tracing
  alias RigInboundGateway.ApiProxy.Handler
  @behaviour Handler
  alias RigInboundGateway.ApiProxy.ResponseFromParser
  alias RigMetrics.ProxyMetrics

  @help_text """
  Produce the request to a Kafka topic and optionally wait for the (correlated) response.

  Expects a JSON encoded CloudEvent in the HTTP body.

  Optionally set a partition key via this field:

  `rig`: {\"target_partition\":\"the-partition-key\"}
  """

  # ---

  @spec validate(any()) :: {:ok, any()}
  def validate(conf), do: {:ok, conf}

  # ---

  @spec kafka_handler(Cloudevents.kafka_body(), Cloudevents.kafka_headers()) ::
          :ok
          | {:error, %{:__exception__ => true, :__struct__ => atom(), optional(atom()) => any()},
             any()}
  def kafka_handler(message, headers) do
    case ResponseFromParser.parse(headers, message) do
      {deserialized_pid, response_code, response, extra_headers} ->
        Logger.debug(fn ->
          "HTTP response via Kafka to #{inspect(deserialized_pid)}: #{inspect(message)}"
        end)

        send(deserialized_pid, {:response_received, response, response_code, extra_headers})

      err ->
        Logger.warn(fn -> "Parse error #{inspect(err)} for #{inspect(message)}" end)
        :ignore
    end

    :ok
  rescue
    err -> {:error, err, message}
  end

  # ---

  @doc @help_text
  @impl Handler
  def handle_http_request(conn, api, endpoint, request_path)

  # CORS response for preflight request.
  def handle_http_request(
        %{method: "OPTIONS"} = conn,
        _,
        %{"target" => "kafka"} = endpoint,
        _
      ) do
    ProxyMetrics.count_proxy_request(
      conn.method,
      conn.request_path,
      "kafka",
      Map.get(endpoint, "response_from", "http"),
      "ok"
    )

    conn
    |> with_cors()
    |> Conn.send_resp(:no_content, "")
  end

  def handle_http_request(
        conn,
        _,
        %{"target" => "kafka", "topic" => topic} = endpoint,
        request_path
      )
      when byte_size(topic) > 0 do
    response_from = Map.get(endpoint, "response_from", "http")
    schema = Map.get(endpoint, "schema")

    conn.assigns[:body]
    |> Jason.decode()
    |> case do
      {:ok, %{"specversion" => _, "rig" => %{"target_partition" => partition}} = event} ->
        do_handle_http_request(
          conn,
          request_path,
          partition,
          event,
          response_from,
          topic,
          schema
        )

      {:ok, %{"specversion" => _} = event} ->
        do_handle_http_request(conn, request_path, <<>>, event, response_from, topic, schema)

      {:ok, _} ->
        respond_with_bad_request(conn, response_from, "the body does not look like a CloudEvent")

      {:error, _} ->
        respond_with_bad_request(conn, response_from, "expected a JSON encoded request body")
    end
  end

  # ---

  def do_handle_http_request(
        conn,
        request_path,
        partition,
        event,
        response_from,
        topic \\ nil,
        schema \\ nil
      ) do
    kafka_message =
      event
      |> Map.put("rig", %{
        correlation: Codec.serialize(self()),
        remoteip: to_string(:inet_parse.ntoa(conn.remote_ip)),
        host: conn.host,
        port: conn.port,
        scheme: conn.scheme,
        headers: Enum.map(conn.req_headers, &Tuple.to_list(&1)),
        method: conn.method,
        path: request_path,
        query: conn.query_string
      })
      |> Tracing.append_context(Tracing.context())
      |> Jason.encode!()

    produce(partition, kafka_message, topic, schema)

    wait_for_response? =
      case response_from do
        "kafka" -> true
        _ -> false
      end

    conn = with_cors(conn)

    if wait_for_response? do
      wait_for_response(conn, response_from)
    else
      ProxyMetrics.count_proxy_request(
        conn.method,
        conn.request_path,
        "kafka",
        response_from,
        "ok"
      )

      Conn.send_resp(conn, :accepted, "Accepted.")
    end
  end

  # ---

  def respond_with_bad_request(conn, response_from, description) do
    response = """
    Bad request: #{description}.

    # Usage

    #{@help_text}
    """

    ProxyMetrics.count_proxy_request(
      conn.method,
      conn.request_path,
      "kafka",
      response_from,
      "bad_request"
    )

    Conn.send_resp(conn, :bad_request, response)
  end

  # ---

  defp wait_for_response(conn, response_from) do
    conf = config()

    receive do
      {:response_received, response, response_code, extra_headers} ->
        ProxyMetrics.count_proxy_request(
          conn.method,
          conn.request_path,
          "kafka",
          response_from,
          "ok"
        )

        conn
        |> Tracing.Plug.put_resp_header(Tracing.context())
        |> Map.update!(:resp_headers, fn existing_headers ->
          existing_headers ++ Map.to_list(extra_headers)
        end)
        |> Conn.send_resp(response_code, response)
    after
      conf.response_timeout ->
        ProxyMetrics.count_proxy_request(
          conn.method,
          conn.request_path,
          "kafka",
          response_from,
          "response_timeout"
        )

        conn
        |> Tracing.Plug.put_resp_header(Tracing.context())
        |> Conn.send_resp(:gateway_timeout, "")
    end
  end

  # ---

  defp produce(server \\ __MODULE__, key, plaintext, topic, schema) do
    GenServer.call(server, {:produce, key, plaintext, topic, schema})
  end

  # ---

  @impl GenServer
  def handle_call(
        {:produce, key, plaintext, topic, schema},
        _from,
        %{kafka_config: kafka_config} = state
      ) do
    res =
      RigKafka.produce(
        kafka_config,
        topic,
        schema,
        key,
        plaintext
      )

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
