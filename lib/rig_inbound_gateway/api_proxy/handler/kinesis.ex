defmodule RigInboundGateway.ApiProxy.Handler.Kinesis do
  @moduledoc """
  Handles requests for Kinesis targets.

  """
  use Rig.Config, :custom_validation

  alias ExAws
  alias Plug.Conn
  alias Rig.Connection.Codec
  alias RIG.Tracing
  alias RigInboundGateway.ApiProxy.Handler
  alias RigMetrics.EventsMetrics
  alias RigMetrics.ProxyMetrics
  alias UUID

  require Logger

  @metrics_target_label "kinesis"

  @behaviour Handler

  @help_text """
  Produce the request to a Kinesis topic and optionally wait for the (correlated) response.

  Expects a JSON encoded CloudEvent in the HTTP body.

  Optionally set a partition key via this field:

  `rig`: {\"target_partition\":\"the-partition-key\"}
  """
  # ---

  # Confex callback
  defp validate_config!(config) do
    kinesis_endpoint = Keyword.fetch!(config, :kinesis_endpoint)
    kinesis_request_region = Keyword.fetch!(config, :kinesis_request_region)

    # try to construct local configuration for Kinesis
    kinesis_options =
      if byte_size(kinesis_endpoint) > 0 do
        %{port: port, host: host, scheme: scheme} = URI.parse(kinesis_endpoint)
        %{port: port, host: host, scheme: "#{scheme}://"}
      else
        %{}
      end

    %{
      kinesis_request_region: kinesis_request_region,
      response_timeout: Keyword.fetch!(config, :response_timeout),
      cors: Keyword.fetch!(config, :cors),
      kinesis_endpoint: Keyword.fetch!(config, :kinesis_endpoint),
      kinesis_options: Map.merge(%{region: kinesis_request_region}, kinesis_options)
    }
  end

  # ---

  @doc @help_text
  @impl Handler
  def handle_http_request(conn, api, endpoint, request_path)

  # CORS response for preflight request.
  def handle_http_request(
        %{method: "OPTIONS"} = conn,
        _,
        %{"target" => "kinesis"} = endpoint,
        _
      ) do
    ProxyMetrics.count_proxy_request(
      conn.method,
      conn.request_path,
      "kinesis",
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
        %{"target" => "kinesis", "topic" => topic} = endpoint,
        request_path
      )
      when byte_size(topic) > 0 do
    response_from = Map.get(endpoint, "response_from", "http")

    conn.assigns[:body]
    |> Jason.decode()
    |> case do
      {:ok, %{"specversion" => _, "rig" => %{"target_partition" => partition}} = event} ->
        do_handle_http_request(conn, request_path, partition, event, response_from, topic)

      {:ok, %{"specversion" => _} = event} ->
        do_handle_http_request(conn, request_path, UUID.uuid4(), event, response_from, topic)

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
        topic \\ nil
      ) do
    kinesis_message =
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

    produce(partition, kinesis_message, topic)

    wait_for_response? =
      case response_from do
        # TODO: "kinesis" -> true
        _ -> false
      end

    conn = with_cors(conn)

    if wait_for_response? do
      wait_for_response(conn, response_from)
    else
      ProxyMetrics.count_proxy_request(
        conn.method,
        conn.request_path,
        "kinesis",
        response_from,
        "ok"
      )

      Conn.send_resp(conn, :accepted, "Accepted.")
    end
  end

  def respond_with_bad_request(conn, response_from, description) do
    response = """
    Bad request: #{description}.

    # Usage

    #{@help_text}
    """

    ProxyMetrics.count_proxy_request(
      conn.method,
      conn.request_path,
      "kinesis",
      response_from,
      "bad_request"
    )

    Conn.send_resp(conn, :bad_request, response)
  end

  # --- Not used at the moment

  defp wait_for_response(conn, response_from) do
    conf = config()

    receive do
      {:response_received, response} ->
        ProxyMetrics.count_proxy_request(
          conn.method,
          conn.request_path,
          "kinesis",
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
          "kinesis",
          response_from,
          "response_timeout"
        )

        conn
        |> Tracing.Plug.put_resp_header(Tracing.context())
        |> Conn.send_resp(:gateway_timeout, "")
    end
  end

  # ---

  defp produce(partition_key, plaintext, topic) do
    conf = config()

    case ExAws.Kinesis.put_record(
           _topic = topic,
           _partition_key = partition_key,
           _data = plaintext
         )
         |> ExAws.request(conf.kinesis_options) do
      {:ok, _} ->
        # increase Prometheus metric with a produced event
        EventsMetrics.count_produced_event(@metrics_target_label, topic)

      err ->
        # increase Prometheus metric with an event failed to be produced
        EventsMetrics.count_failed_produce_event(@metrics_target_label, topic)

        Logger.error(fn ->
          "Error occurred when producing Kinesis event to topic #{topic}, #{inspect(err)}"
        end)
    end
  end

  # ---

  defp with_cors(conn) do
    conn
    |> Conn.put_resp_header("access-control-allow-origin", config().cors)
    |> Conn.put_resp_header("access-control-allow-methods", "*")
    |> Conn.put_resp_header("access-control-allow-headers", "content-type,authorization")
  end
end
