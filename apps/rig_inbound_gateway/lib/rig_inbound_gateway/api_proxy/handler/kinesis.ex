defmodule RigInboundGateway.ApiProxy.Handler.Kinesis do
  @moduledoc """
  Handles requests for Kinesis targets.

  """
  use Rig.Config, [:kinesis_request_stream, :kinesis_request_region, :response_timeout]

  alias ExAws
  alias Plug.Conn

  alias Rig.Connection.Codec

  alias RigInboundGateway.ApiProxy.Handler
  @behaviour Handler

  # ---

  @impl Handler
  def handle_http_request(conn, api, endpoint)

  @doc "CORS response for preflight request."
  def handle_http_request(%{method: "OPTIONS"} = conn, _, %{"target" => "kinesis"}) do
    conn
    |> with_cors()
    |> Conn.send_resp(:no_content, "")
  end

  @doc "Produce request to Kafka topic and optionally wait for response."
  def handle_http_request(conn, _, %{"target" => "kinesis"} = endpoint) do
    %{params: %{"partition_key" => partition_key, "data" => data}} = conn

    kinesis_message =
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
      _plaintext = kinesis_message
    )

    wait_for_response? =
      case Map.get(endpoint, "response_from") do
        # TODO: "kinesis" -> true
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

  defp produce(partition_key, plaintext) do
    conf = config()

    ExAws.Kinesis.put_record(
      _stream_name = conf.kinesis_request_stream,
      _partition_key = partition_key,
      _data = plaintext
    )
    |> ExAws.request(region: conf.kinesis_request_region)
  end

  # ---

  defp with_cors(conn) do
    conn
    |> Conn.put_resp_header("access-control-allow-origin", config().cors)
    |> Conn.put_resp_header("access-control-allow-methods", "*")
    |> Conn.put_resp_header("access-control-allow-headers", "content-type,authorization")
  end
end
