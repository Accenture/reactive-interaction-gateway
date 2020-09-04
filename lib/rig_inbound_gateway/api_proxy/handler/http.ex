defmodule RigInboundGateway.ApiProxy.Handler.Http do
  @moduledoc """
  Handles requests for HTTP targets.

  """
  use Rig.Config, [
    :cors,
    :kafka_response_timeout,
    :kinesis_response_timeout,
    :http_async_response_timeout
  ]

  require Logger
  alias HTTPoison
  alias Plug.Conn
  alias Plug.Conn.Query

  alias Rig.Connection.Codec
  alias RIG.Tracing
  alias RigInboundGateway.ApiProxy.Base
  alias RigInboundGateway.ApiProxy.Handler
  alias RigInboundGateway.ApiProxy.Handler.HttpHeader
  alias RigMetrics.ProxyMetrics
  @behaviour Handler

  # ---

  @impl Handler
  def handle_http_request(conn, api, endpoint, request_path) do
    %{method: method, req_headers: req_headers} = conn
    body = conn.assigns[:body]
    response_from = Map.get(endpoint, "response_from", "http")

    url =
      build_url(api["proxy"], request_path)
      |> add_query_params(conn.query_string)
      |> possibly_add_correlation_id(response_from)

    host_ip = Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:url][:host]

    req_headers =
      req_headers
      |> HttpHeader.put_host_header(url)
      |> HttpHeader.put_forward_header(conn.remote_ip, host_ip)
      |> Tracing.Plug.put_req_header(Tracing.context())
      |> drop_connection_related_headers()

    result = do_request(method, url, body, req_headers)

    case result do
      {:ok, res} ->
        handle_response(conn, res, response_from)

      {:error, err} ->
        Logger.warn(fn ->
          "Failed to proxy to #{inspect(url)} (#{method} #{request_path}): #{inspect(err)}"
        end)

        count_http_request_error(conn, err.reason, response_from)

        Conn.send_resp(conn, :bad_gateway, "Bad gateway.")

      :unknown_method ->
        Conn.send_resp(conn, :method_not_allowed, "Method not allowed.")
    end
  end

  # ---

  defp do_request(method, url, body, req_headers) do
    case method do
      "GET" -> Base.get(url, req_headers)
      "POST" -> Base.post(url, body, req_headers)
      "PUT" -> Base.put(url, body, req_headers)
      "PATCH" -> Base.patch(url, body, req_headers)
      "DELETE" -> Base.delete(url, req_headers)
      "HEAD" -> Base.head(url, req_headers)
      "OPTIONS" -> Base.options(url, req_headers)
      _ -> :unknown_method
    end
  end

  # ---

  defp handle_response(conn, res, response_from)

  defp handle_response(conn, res, "http"),
    do: send_or_chunk_response(conn, res)

  defp handle_response(conn, _, response_from),
    do: wait_for_response(conn, response_from)

  # ---

  defp wait_for_response(conn, response_from) do
    conf = config()

    response_timeout =
      case response_from do
        "kafka" -> conf.kafka_response_timeout
        "kinesis" -> conf.kinesis_response_timeout
        "http_async" -> conf.http_async_response_timeout
      end

    receive do
      {:response_received, response, response_code, extra_headers} ->
        ProxyMetrics.count_proxy_request(
          conn.method,
          conn.request_path,
          "http",
          response_from,
          "ok"
        )

        conn
        |> with_cors()
        |> Tracing.Plug.put_resp_header(Tracing.context())
        |> Map.update!(:resp_headers, fn existing_headers ->
          existing_headers ++ Map.to_list(extra_headers)
        end)
        |> Conn.send_resp(response_code, response)
    after
      response_timeout ->
        ProxyMetrics.count_proxy_request(
          conn.method,
          conn.request_path,
          "http",
          response_from,
          "response_timeout"
        )

        conn
        |> with_cors()
        |> Tracing.Plug.put_resp_header(Tracing.context())
        |> Conn.send_resp(:gateway_timeout, "")
    end
  end

  # ---

  @spec build_url(Proxy.api_definition() | %URI{}, String.t()) :: String.t()

  def build_url(%URI{} = proxy_uri, request_path) do
    proxy_uri
    |> URI.merge(request_path)
    |> URI.to_string()
  end

  def build_url(%{"use_env" => true, "target_url" => target_url} = proxy, request_path) do
    host = System.get_env(target_url) || "localhost"
    build_url(%{proxy | "target_url" => host, "use_env" => false}, request_path)
  end

  def build_url(%{"target_url" => target_url, "port" => port}, request_path)
      when is_integer(port) do
    default_scheme = "http"

    {scheme, host} =
      case URI.parse(target_url) do
        %{scheme: nil, host: nil, path: host} -> {default_scheme, host}
        %{scheme: scheme, host: host} -> {scheme, host}
      end

    "#{scheme}://#{host}:#{port}"
    |> URI.parse()
    |> build_url(request_path)
  end

  # ---

  defp possibly_add_correlation_id(url, response_from)

  defp possibly_add_correlation_id(url, "http"), do: url

  defp possibly_add_correlation_id(url, _) do
    add_query_params(url, %{"correlation" => Codec.serialize(self())})
  end

  # ---

  def add_query_params(uri_text, params) when is_map(params) do
    uri = URI.parse(uri_text)
    # Query supports nested query parameters - URI doesn't.
    query = (uri.query || "") |> Query.decode() |> Map.merge(params) |> Query.encode()
    %{uri | query: query} |> URI.to_string()
  end

  def add_query_params(uri_text, query_string) do
    params = Query.decode(query_string)
    add_query_params(uri_text, params)
  end

  # ---

  @spec send_or_chunk_response(Plug.Conn.t(), HTTPoison.Response.t()) :: Plug.Conn.t()
  defp send_or_chunk_response(
         conn,
         %HTTPoison.Response{
           headers: headers,
           status_code: status_code,
           body: body
         }
       ) do
    headers =
      headers
      |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
      |> drop_connection_related_headers()

    conn = %{conn | resp_headers: headers}

    # only possibility for "response_from" = "http", therefore hardcoded here
    ProxyMetrics.count_proxy_request(conn.method, conn.request_path, "http", "http", "ok")

    headers
    |> Map.new()
    |> Map.get("transfer-encoding")
    |> case do
      "chunked" -> send_chunked_response(conn, status_code, body)
      _ -> Conn.send_resp(conn, status_code, body)
    end
  end

  # ---

  @spec send_chunked_response(Plug.Conn.t(), integer, String.t()) :: Plug.Conn.t()
  defp send_chunked_response(conn, status_code, body) do
    chunked_conn = Conn.send_chunked(conn, status_code)
    Conn.chunk(chunked_conn, body)
    chunked_conn
  end

  # ---

  defp with_cors(conn) do
    conn
    |> Conn.put_resp_header("access-control-allow-origin", config().cors)
    |> Conn.put_resp_header("access-control-allow-methods", "*")
    |> Conn.put_resp_header("access-control-allow-headers", "content-type")
  end

  # ---

  defp count_http_request_error(conn, :timeout, response_from) do
    ProxyMetrics.count_proxy_request(
      conn.method,
      conn.request_path,
      "http",
      response_from,
      "request_timeout"
    )
  end

  defp count_http_request_error(conn, _, response_from) do
    ProxyMetrics.count_proxy_request(
      conn.method,
      conn.request_path,
      "http",
      response_from,
      "unreachable"
    )
  end

  # ---

  defp drop_connection_related_headers(headers) do
    # Connection related headers break HTTP/2
    # (and it doesn't make sense to forward them anyway).
    # See https://tools.ietf.org/html/rfc7540#section-8.1.2.2

    headers
    |> Enum.map(fn {k, v} -> {String.downcase(k), v} end)
    |> Enum.filter(fn
      {k, _}
      when k in [
             "connection",
             "keep-alive",
             "proxy-connection",
             "transfer-encoding",
             "upgrade",
             "http2-settings"
           ] ->
        false

      _ ->
        true
    end)
  end
end
