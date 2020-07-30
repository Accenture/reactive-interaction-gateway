defmodule RigInboundGateway.ApiProxy.Handler.Kafka do
  @moduledoc """
  Handles requests for Kafka targets.

  """
  use Rig.KafkaConsumerSetup, [:cors, :request_topic, :request_schema, :response_timeout]

  alias Plug.Conn

  alias RigMetrics.ProxyMetrics

  alias RigInboundGateway.ApiProxy.Handler
  @behaviour Handler

  alias Rig.Connection.Codec

  alias RIG.Tracing

  @help_text """
  Produce the request to a Kafka topic and optionally wait for the (correlated) response.

  Expects a JSON encoded HTTP body with the following fields:

  - `event`: The published CloudEvent >= v0.2. The event is extended by metadata
  written to the "rig" extension field (following the CloudEvents v0.2 spec).
  - `partition`: The targetted Kafka partition.

  or

  ...
  CloudEvent
  ...
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
    with {:ok, event} <- Cloudevents.from_kafka_message(message, headers),
         {:ok, rig_metadata} <- Map.fetch(event.extensions, "rig"),
         {:ok, correlation_id} <- Map.fetch(rig_metadata, "correlation"),
         {:ok, deserialized_pid} <- Codec.deserialize(correlation_id) do
      Logger.debug(fn ->
        "HTTP response via Kafka to #{inspect(deserialized_pid)}: #{inspect(message)}"
      end)

      data =
        if headers == [],
          do: Cloudevents.to_json(event),
          else: Jason.encode!(event.data)

      send(deserialized_pid, {:response_received, data})
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

  @doc @help_text
  @impl Handler
  def handle_http_request(conn, api, endpoint, request_path)

  @doc "CORS response for preflight request."
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
      # Deprecated way to pass events:
      {:ok, %{"partition" => partition, "event" => event}} ->
        do_handle_http_request(
          conn,
          request_path,
          partition,
          event,
          response_from,
          topic,
          schema
        )

      # Preferred way to pass events, where the partition goes into the "rig" extension:
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

      # Deprecated way to pass events, partition not set -> will be randomized:
      {:ok, %{"event" => event}} ->
        do_handle_http_request(conn, request_path, <<>>, event, response_from, topic)

      # Preferred way to pass events, partition not set -> will be randomized:
      {:ok, %{"specversion" => _} = event} ->
        do_handle_http_request(conn, request_path, <<>>, event, response_from, topic)

      {:ok, _} ->
        respond_with_bad_request(conn, response_from, "the body does not look like a CloudEvent")

      {:error, _} ->
        respond_with_bad_request(conn, response_from, "expected a JSON encoded request body")
    end
  end

  @deprecated "Using environemnt variables to set Kafka proxy request topic and schema is deprecated.
  Set these values directly in proxy json file"
  def handle_http_request(
        conn,
        _,
        %{"target" => "kafka"} = endpoint,
        request_path
      ) do
    response_from = Map.get(endpoint, "response_from", "http")

    conn.assigns[:body]
    |> Jason.decode()
    |> case do
      # Deprecated way to pass events:
      {:ok, %{"partition" => partition, "event" => event}} ->
        do_handle_http_request(conn, request_path, partition, event, response_from)

      # Preferred way to pass events, where the partition goes into the "rig" extension:
      {:ok, %{"specversion" => _, "rig" => %{"target_partition" => partition}} = event} ->
        do_handle_http_request(conn, request_path, partition, event, response_from)

      # Deprecated way to pass events, partition not set -> will be randomized:
      {:ok, %{"event" => event}} ->
        do_handle_http_request(conn, request_path, <<>>, event, response_from)

      # Preferred way to pass events, partition not set -> will be randomized:
      {:ok, %{"specversion" => _} = event} ->
        do_handle_http_request(conn, request_path, <<>>, event, response_from)

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
      |> Poison.encode!()

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
      {:response_received, response} ->
        ProxyMetrics.count_proxy_request(
          conn.method,
          conn.request_path,
          "kafka",
          response_from,
          "ok"
        )

        conn
        |> Tracing.Plug.put_resp_header(Tracing.context())
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(:ok, response)
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
    %{request_topic: request_topic, request_schema: request_schema} = config()

    res =
      RigKafka.produce(
        kafka_config,
        topic || request_topic,
        schema || request_schema,
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
