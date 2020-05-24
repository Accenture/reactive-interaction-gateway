defmodule RigInboundGateway.ApiProxy.Handler.Nats do
  @moduledoc """
  Handles requests for NATS targets.

  """
  require Logger
  use Rig.Config, [:timeout, :cors]

  alias Plug.Conn
  alias Rig.Connection.Codec
  alias RigCloudEvents.CloudEvent
  alias RigInboundGateway.ApiProxy.Handler
  alias RigMetrics.ProxyMetrics

  @behaviour Handler

  @help_text """
  Produce the request to a NATS topic and optionally wait for the response.

  Expects a JSON encoded CloudEvent in the HTTP body.
  """

  @impl Handler
  def handle_http_request(conn, api, endpoint, request_path)

  @doc "CORS response for preflight request."
  def handle_http_request(%{method: "OPTIONS"} = conn, _, %{"target" => "nats"} = endpoint, _) do
    conn
    |> with_cors()
    |> Conn.send_resp(:no_content, "")
  end

  @doc @help_text
  def handle_http_request(conn, api, endpoint, request_path)

  def handle_http_request(
        conn,
        _,
        %{"target" => "nats", "topic" => topic} = endpoint,
        request_path
      )
      when byte_size(topic) > 0 do
    conn = with_cors(conn)
    response_from = Map.get(endpoint, "response_from", "http")

    case Jason.decode(conn.assigns[:body]) do
      {:ok, %{"specversion" => _} = event} ->
        do_handle_http_request(conn, request_path, event, response_from, topic)

      error ->
        message =
          case error do
            {:ok, obj} -> "The body is a valid JSON object but does not look like a CloudEvent."
            {:error, error} -> "The body is not JSON encoded (#{inspect(error)})."
          end

        response = """
        Bad request: #{message}

        # Usage

        #{@help_text}
        """

        Logger.debug(fn -> "Received invalid request to NATS proxy: #{inspect(error)}" end)
        count_request(conn, response_from, "bad_request")
        Conn.send_resp(conn, :bad_request, response)
    end
  end

  # ---

  def do_handle_http_request(conn, request_path, event, response_from, topic) do
    message = event |> add_metadata(conn, request_path) |> Jason.encode!()

    wait_for_response? =
      case response_from do
        "nats" -> true
        _ -> false
      end

    %{timeout: timeout} = config()

    if wait_for_response? do
      case Gnat.request(:nats, topic, message, receive_timeout: timeout) do
        {:ok, %{body: response}} ->
          count_request(conn, response_from, "ok")

          conn
          |> Conn.put_resp_content_type("application/json")
          |> Conn.send_resp(:ok, response)

        {:error, :timeout} ->
          count_request(conn, response_from, "response_timeout")
          Conn.send_resp(conn, :gateway_timeout, "Timed out while waiting for the response.")
      end
    else
      Gnat.pub(:nats, topic, message)
      count_request(conn, response_from, "ok")
      Conn.send_resp(conn, :accepted, "Accepted.")
    end
  end

  # ---

  defp add_metadata(event, conn, request_path) do
    Map.put(event, "rig", %{
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
  end

  # ---

  defp with_cors(conn) do
    conn
    |> Conn.put_resp_header("access-control-allow-origin", config().cors)
    |> Conn.put_resp_header("access-control-allow-methods", "*")
    |> Conn.put_resp_header("access-control-allow-headers", "content-type,authorization")
  end

  # ---

  defp count_request(conn, response_from, status) do
    ProxyMetrics.count_proxy_request(
      conn.method,
      conn.request_path,
      "nats",
      response_from,
      status
    )
  end
end
