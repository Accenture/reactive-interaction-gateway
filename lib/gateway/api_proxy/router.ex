defmodule Gateway.ApiProxy.Router do
  @moduledoc """
  Provides middleware proxy for incoming REST requests at specific endpoints.
  Matches all incoming HTTP requests and checks if such endpoint is defined in json file.
  If endpoint needs authentication, it is automatically triggered.
  Valid HTTP requests are forwarded to given service and their response is sent back to client.
  """
  use Plug.Router
  require Logger

  alias Plug.Conn.Query
  alias Gateway.ApiProxy.Base
  alias Gateway.Utils.Jwt
  alias Gateway.Kafka
  alias Gateway.RateLimit
  alias Gateway.Proxy

  @typep route_map :: %{required(String.t) => String.t}

  plug :match
  plug :dispatch

  # Get all incoming HTTP requests, check if they are valid, provide authentication if needed
  match _ do
    %{method: request_method, request_path: request_path} = conn
    # IO.puts "CALL"
    # IO.inspect Gateway.Proxy.list_apis
    # Load proxy routes during the runtime
    # fd =
    # :gateway
    # |> :code.priv_dir
    # |> Path.join(@config_file)
    # |> File.read!
    # |> Poison.decode!

    # IO.inspect fd

    # ps =
    # Proxy.list_apis
    # |> Enum.map(fn(api) ->
    #   {_id, api_definition} = api
    #   IO.inspect api_definition
    #   api_definition
    # end)
    # 
    # IO.inspect ps

    IO.inspect "PICKER"
    IO.inspect conn
    list_apis = Proxy.list_apis
    |> Enum.map(fn(api) ->
      {_id, api_definition} = api
      api_definition
    end)
    list_length = length(list_apis)
    {ap, endp} = pick_endpoint(list_apis, request_path, request_method, list_length)
    # IO.puts "END"
    # IO.inspect ap
    # IO.inspect endp

    # {service, endpoint} =
    #   # :gateway
    #   # |> :code.priv_dir
    #   # |> Path.join(@config_file)
    #   # |> File.read!
    #   # |> Poison.decode!
    #   Proxy.list_apis
    #   |> Enum.map(fn(api) ->
    #     {_id, api_definition} = api
    #     api_definition
    #   end)
    #   |> Enum.find?(fn(api) ->
    #     IO.puts "MATCH PATH & METHOD"
    #     IO.inspect api
    #     # IO.inspect match_path(api, request_path)
    #     validate_request(api, request_path, request_method)
    #     # match_path(route, request_path) && match_http_method(route, method)
    #   end)
    #   # |> pick_endpoint
    # 
    # IO.puts "SERVICE"
    # IO.inspect service

    case endp do
      nil ->
        send_resp(conn, 404, encode_error_message("Route is not available"))
      _ ->
        IO.puts "RATE LIMITING"
        source_ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
        %{"port" => port, "target_url" => host} = Map.fetch!(ap, "proxy")
        endpoint = "#{host}:#{port}"
        IO.inspect endpoint
        endpoint
        |> RateLimit.request_passage(source_ip)
        |> case do
          :ok ->
            IO.puts "CHECK AUTH"
            IO.inspect endp
            check_auth_and_forward_request(endp, ap, conn)
          :passage_denied ->
            Logger.warn("Too many requests (429) from #{source_ip} to #{endpoint}.")
            send_resp(conn, 429, encode_error_message("Too many requests."))
        end
    end
  end

  # Recursively search for valid endpoint and return API definition and matched endpoint
  defp pick_endpoint([head | tail], request_path, request_method, iterator) when iterator >= 1 do
    IO.inspect iterator
    IO.inspect head
    res = validate_request(head, request_path, request_method)
    # IO.inspect res
    # IO.inspect iterator > 1
    cond do
      res == nil && iterator > 1 -> pick_endpoint(tail, request_path, request_method, iterator - 1)
      true -> {head, res}
    end
    # if res == nil && iterator > 1 do
    #   IO.inspect tail
    #   pick_endpoint(tail, request_path, request_method, iterator - 1)
    # end
    # IO.inspect "END #{iterator}"
    # IO.inspect res
    # {head, res}
  end

  # Validate API definition if there is any valid endpoint, match path and HTTP method
  defp validate_request(%{"versioned" => false} = route, request_path, request_method) do # TODO: VERSIONED APIs
    IO.puts "NON VERSIONED API"
    endpoints = Kernel.get_in(route, ["version_data", "default", "endpoints"])

    endpoints
    |> Enum.find(fn(endpoint) ->
      %{"path" => path, "method" => method} = endpoint
      match_path(path, request_path) && match_http_method(method, request_method)
    end)
  end

  # Match route path against requested path
  @spec match_path(route_map, String.t) :: boolean
  defp match_path(path, request_path) do
    # Replace wildcards with actual params
    full_path = String.replace(path, "{id}", "[^/]+")
    String.match?(request_path, ~r/#{full_path}$/)

    # replace_wildcards = String.replace(route["path"], "{id}", "[^/]+")
    # Match requested path against regex
    # String.match?(request_path, ~r/#{replace_wildcards}$/)
  end

  # Match route method against requested method
  @spec match_http_method(route_map, String.t) :: boolean
  defp match_http_method(method, request_method), do: method == request_method

  # Encode custom error messages with Poison to JSON format
  @type json_message :: %{message: String.t}
  @spec encode_error_message(String.t) :: json_message
  defp encode_error_message(message) do
    Poison.encode!(%{message: message})
  end

  # @spec check_auth_and_forward_request(route_map, %Plug.Conn{}) :: %Plug.Conn{}
  # Authentication required
  defp check_auth_and_forward_request(endpoint = %{"secured" => true}, api, conn) do
    IO.puts "SECURED"
    # Get authorization from request header and query param (returns a list):
    tokens =
      conn
      |> Map.get(:query_params)
      |> Map.get("token", "")
      |> String.split
      |> Enum.concat(get_req_header(conn, "authorization"))

    case any_token_valid?(tokens) do
      true -> forward_request(endpoint, api, conn)
      false -> send_resp(conn, 401, encode_error_message("Missing or invalid token"))
    end
  end
  # Authentication not required
  defp check_auth_and_forward_request(endpoint = %{"secured" => false}, api, conn) do
    IO.puts "NOT SECURED"
    forward_request(endpoint, api, conn)
  end

  @spec any_token_valid?([]) :: false
  defp any_token_valid?([]), do: false
  @spec any_token_valid?([String.t, ...]) :: boolean
  defp any_token_valid?(tokens) do
    tokens |> Enum.any?(&Jwt.valid?/1)
  end

  # @spec forward_request(route_map, %Plug.Conn{}) :: %Plug.Conn{}
  defp forward_request(endpoint, api, conn) do
    log_to_kafka(endpoint, conn)
    %{
      method: method,
      request_path: request_path,
      params: params,
      req_headers: req_headers
    } = conn
    # Build URL
    url = build_url(api["proxy"], request_path)
    IO.inspect "URL #{url}"
    # Match URL against HTTP method to forward it to specific service
    res =
      case method do
        "GET" -> Base.get!(attachQueryParams(url, params), req_headers)
        "POST" -> format_post_request(url, params, req_headers)
        "PUT" -> Base.put!(url, Poison.encode!(params), req_headers)
        "PATCH" -> Base.patch!(url, Poison.encode!(params), req_headers)
        "DELETE" -> Base.delete!(url, req_headers)
        "HEAD" -> Base.head!(url, req_headers)
        "OPTIONS" -> Base.options!(url, req_headers)
        _ -> nil
      end
    send_response({:ok, conn, res})
  end

  @spec format_post_request(String.t, %{required(String.t) => %Plug.Upload{}}, map) :: %Plug.Conn{}
  defp format_post_request(url, %{"qqfile" => %Plug.Upload{}} = params, headers) do
    %{"qqfile" => file} = params
    optional_params = params |> Map.delete("qqfile")
    params_merged = Enum.concat(
      optional_params,
      [{:file, file.path}, {"content-type", file.content_type}, {"filename", file.filename}]
    )

    Base.post!(url, {:multipart, params_merged}, headers)
  end

  @spec format_post_request(String.t, map, map) :: %Plug.Conn{}
  defp format_post_request(url, params, headers) do
    Base.post!(url, Poison.encode!(params), headers)
  end

  @spec log_to_kafka(route_map, %Plug.Conn{}) :: :ok
  defp log_to_kafka(%{"secured" => true} = proxy, conn) do
    Kafka.log_proxy_api_call(proxy, conn)
  end
  defp log_to_kafka(_service, _conn) do
    # no-op - we only log authenticated requests for now.
    :ok
  end

  # Builds URL where REST request should be proxied
  @spec build_url(route_map, String.t) :: String.t
  defp build_url(proxy = %{"use_env" => true}, request_path) do # TODO: HANDLE FALSE
    host = System.get_env(proxy["target_url"]) || "localhost"
    "#{host}:#{proxy["port"]}#{request_path}"
  end

  # Workaround for HTTPoison/URI.encode not supporting nested query params
  @spec attachQueryParams(String.t, nil) :: String.t
  defp attachQueryParams(url, params) when params == %{}, do: url

  @spec attachQueryParams(String.t, map) :: String.t
  defp attachQueryParams(url, params) do
    url <> "?" <> Query.encode(params)
  end

  # Function for sending response back to client
  @spec send_response({:ok, %Plug.Conn{}, nil}) :: %Plug.Conn{}
  defp send_response({:ok, conn, nil}) do
    send_resp(conn, 405, encode_error_message("Method is not supported"))
  end

  @spec send_response({:ok, %Plug.Conn{}, map}) :: %Plug.Conn{}
  defp send_response({:ok, conn, %{headers: headers, status_code: status_code, body: body}}) do
    conn = %{conn | resp_headers: headers}
    if header_value?(conn, "transfer-encoding", "chunked") do
      send_chunked_response(conn, headers, status_code, body)
    else
      %{conn | resp_headers: headers} |> send_resp(status_code, body)
    end
  end

  # Evaluate if headers contain value, downcases keys to avoid mismatches
  @spec header_value?(%Plug.Conn{}, String.t, String.t) :: boolean
  defp header_value?(conn, key, value) do
    conn
    |> Map.get(:resp_headers)
    |> Enum.find({}, fn(headers_tuple) ->
      key_downcase =
        headers_tuple
        |> elem(0)
        |> String.downcase
      key_downcase == key
    end)
    |> Tuple.to_list
    |> Enum.member?(value)
  end

  # Sends chunked response with body and set transfer-encoding to client
  @spec send_chunked_response(%Plug.Conn{}, [String.t, ...], integer, map) :: %Plug.Conn{}
  defp send_chunked_response(conn, headers, status_code, body) do
    conn = %{conn | resp_headers: headers} |> send_chunked(status_code)
    conn |> chunk(body)
    conn
  end
end
