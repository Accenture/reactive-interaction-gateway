defmodule RigInboundGateway.ApiProxy.Handler.Http do
  @moduledoc """
  Handles requests for HTTP targets.

  """
  use Rig.Config, [:cors, :kafka_response_timeout, :kinesis_response_timeout]
  require Logger
  alias HTTPoison
  alias Plug.Conn
  alias Plug.Conn.Query

  alias Rig.Connection.Codec

  alias RigInboundGateway.ApiProxy.Base

  alias RigInboundGateway.ApiProxy.Handler
  @behaviour Handler

  # ---

  @impl Handler
  def handle_http_request(conn, api, endpoint) do
    %{
      method: method,
      request_path: request_path,
      params: params,
      req_headers: req_headers
    } = conn

    response_from = Map.get(endpoint, "response_from", "http")

    url =
      build_url(api["proxy"], request_path)
      |> possibly_add_correlation_id(response_from)

    result = do_request(method, url, params, req_headers)

    case result do
      {:ok, res} ->
        handle_response(conn, res, response_from)

      {:error, err} ->
        Logger.warn(fn -> "Failed to proxy '#{method} #{request_path}': #{inspect(err)}" end)
        Conn.send_resp(conn, :bad_gateway, "Bad gateway.")

      :unknown_method ->
        Conn.send_resp(conn, :method_not_allowed, "Method not allowed.")
    end
  end

  # ---

  defp do_request(method, url, params, req_headers) do
    case method do
      "GET" -> Base.get(add_query_params(url, params), req_headers)
      "POST" -> do_post_request(url, params, req_headers)
      "PUT" -> Base.put(url, Poison.encode!(params), req_headers)
      "PATCH" -> Base.patch(url, Poison.encode!(params), req_headers)
      "DELETE" -> Base.delete(url, req_headers)
      "HEAD" -> Base.head(url, req_headers)
      "OPTIONS" -> Base.options(url, req_headers)
      _ -> :unknown_method
    end
  end

  # ---

  defp handle_response(conn, res, response_from)
  defp handle_response(conn, res, "http"), do: send_or_chunk_response(conn, res)
  defp handle_response(conn, _, response_from), do: wait_for_response(conn, response_from)

  # ---

  defp wait_for_response(conn, response_from) do
    conf = config()

    response_timeout =
      case response_from do
        "kafka" -> conf.kafka_response_timeout
        "kinesis" -> conf.kinesis_response_timeout
      end

    receive do
      {:response_received, response} ->
        conn
        |> with_cors()
        |> Conn.put_resp_content_type("application/json")
        |> Conn.send_resp(:ok, response)
    after
      response_timeout ->
        conn
        |> with_cors()
        |> Conn.send_resp(:gateway_timeout, "")
    end
  end

  # ---

  # Format multipart body and set as POST HTTP method
  @typep map_string_upload :: %{required(String.t()) => %Plug.Upload{}}
  @typep headers :: [{String.t(), String.t()}]

  @spec do_post_request(String.t(), map_string_upload, headers) :: Plug.Conn.t()
  defp do_post_request(url, %{"qqfile" => %Plug.Upload{}} = params, headers) do
    %{"qqfile" => file} = params
    optional_params = params |> Map.delete("qqfile")

    params_merged =
      Enum.concat(
        optional_params,
        [{:file, file.path}, {"content-type", file.content_type}, {"filename", file.filename}]
      )

    Base.post(url, {:multipart, params_merged}, headers)
  end

  @spec do_post_request(String.t(), map, headers) :: Plug.Conn.t()
  defp do_post_request(url, params, headers) do
    Base.post(url, Poison.encode!(params), headers)
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
    add_query_params(url, %{"correlationID" => Codec.serialize(self())})
  end

  # ---

  def add_query_params(uri_text, params) when is_map(params) do
    uri = URI.parse(uri_text)
    # Query supports nested query parameters - URI doesn't.
    query = (uri.query || "") |> Query.decode() |> Map.merge(params) |> Query.encode()
    %{uri | query: query} |> URI.to_string()
  end

  # ---

  @spec send_or_chunk_response(Plug.Conn.t(), HTTPoison.Response.t()) :: Plug.Conn.t()
  defp send_or_chunk_response(conn, %HTTPoison.Response{
         headers: headers,
         status_code: status_code,
         body: body
       }) do
    headers = for {k, v} <- headers, do: {String.downcase(k), v}
    conn = %{conn | resp_headers: headers}

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
end
