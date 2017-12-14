defmodule RigInboundGateway.ApiProxy.Router do
  @moduledoc """
  Provides middleware proxy for incoming REST requests at specific endpoints.
  Initial API definitions are loaded from Phoenix Presence under topic "proxy".
  Matches all incoming HTTP requests and checks if such endpoint is defined in any API.
  If endpoint needs authentication, it is automatically triggered.
  Valid HTTP requests are forwarded to given service and their response is sent back to client.
  """
  use Plug.Router
  require Logger

  alias RigInboundGateway.ApiProxy.Base
  alias RigInboundGateway.ApiProxy.Auth
  alias RigInboundGateway.ApiProxy.Serializer
  alias RigInboundGateway.RateLimit
  alias RigInboundGateway.Proxy

  @typep headers_list :: [{String.t, String.t}, ...]
  @typep map_string_upload :: %{required(String.t) => %Plug.Upload{}}

  plug :match
  plug :dispatch

  # Get all incoming HTTP requests, check if they are valid, provide authentication if needed
  match _ do
    %{method: request_method, request_path: request_path} = conn

    list_apis =
      Proxy
      |> Proxy.list_apis
      |> Enum.map(fn(api) -> elem(api, 1) end)
      |> Enum.filter(fn(api) -> api["active"] == true end)
    {api_map, endpoint} = pick_api_and_endpoint(list_apis, request_path, request_method)

    case endpoint do
      nil ->
        send_resp(conn, 404, Serializer.encode_error_message("Route is not available"))
      _ ->
        source_ip = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
        %{"port" => port, "target_url" => host} = Map.fetch!(api_map, "proxy")
        endpoint_socket = "#{host}:#{port}"
        endpoint_socket
        |> RateLimit.request_passage(source_ip)
        |> case do
          :ok ->
            check_auth_and_forward_request(endpoint, api_map, conn)
          :passage_denied ->
            Logger.warn("Too many requests (429) from #{source_ip} to #{endpoint_socket}.")
            send_resp(conn, 429, Serializer.encode_error_message("Too many requests."))
        end
    end
  end

  # Recursively search for valid endpoint and return API definition and matched endpoint
  @spec pick_api_and_endpoint([], String.t, String.t) :: {nil, nil}
  defp pick_api_and_endpoint([], _request_path, _request_method), do: {nil, nil}
  @spec pick_api_and_endpoint(
    [Proxy.api_definition], String.t, String.t) :: {Proxy.api_definition, Proxy.endpoint}
  defp pick_api_and_endpoint([head | tail], request_path, request_method) do
    endpoint = validate_request(head, request_path, request_method)
    if endpoint == nil do
      pick_api_and_endpoint(tail, request_path, request_method)
    else
      {head, endpoint}
    end
  end

  # Validate API definition if there is any valid endpoint, match path and HTTP method
  @spec validate_request(Proxy.api_definition, String.t, String.t) :: Proxy.endpoint
  defp validate_request(%{"versioned" => false} = route, request_path, request_method) do
    Kernel.get_in(route, ["version_data", "default", "endpoints"])
    |> Enum.find(fn(endpoint) ->
      %{"path" => path, "method" => method} = endpoint
      match_path(path, request_path) && match_http_method(method, request_method)
    end)
  end

  # Match endpoint path against requested path
  @spec match_path(String.t, String.t) :: boolean
  defp match_path(path, request_path) do
    # Replace wildcards with actual params
    full_path = String.replace(path, "{id}", "[^/]+")
    String.match?(request_path, ~r/#{full_path}$/)
  end

  # Match endpoint method against requested method
  @spec match_http_method(String.t, String.t) :: boolean
  defp match_http_method(method, request_method), do: method == request_method

  # Skip authentication if turned off
  @spec check_auth_and_forward_request(
    Proxy.endpoint, Proxy.api_definition, %Plug.Conn{}) :: %Plug.Conn{}
  defp check_auth_and_forward_request(%{"not_secured" => true} = endpoint, api, conn) do
    forward_request(endpoint, api, conn)
  end
  # Skip authentication if no auth type is set
  @spec check_auth_and_forward_request(
    Proxy.endpoint, Proxy.api_definition, %Plug.Conn{}) :: %Plug.Conn{}
  defp check_auth_and_forward_request(endpoint, %{"auth_type" => "none"} = api, conn) do
    forward_request(endpoint, api, conn)
  end
  # Authentication with JWT
  @spec check_auth_and_forward_request(
    Proxy.endpoint, Proxy.api_definition, %Plug.Conn{}) :: %Plug.Conn{}
  defp check_auth_and_forward_request(%{"not_secured" => false} = endpoint, %{"auth_type" => "jwt"} = api, conn) do
    tokens = Enum.concat(Auth.pick_query_token(conn, api), Auth.pick_header_token(conn, api))
    case Auth.any_token_valid?(tokens) do
      true -> forward_request(endpoint, api, conn)
      false -> send_resp(conn, 401, Serializer.encode_error_message("Missing or invalid token"))
    end
  end

  @spec forward_request(Proxy.endpoint, Proxy.api_definition, %Plug.Conn{}) :: %Plug.Conn{}
  defp forward_request(endpoint, api, conn) do
    log_to_kafka(api, endpoint, conn)
    %{
      method: method,
      request_path: request_path,
      params: params,
      req_headers: req_headers
    } = conn

    url = Serializer.build_url(api["proxy"], request_path)

    # Match URL against HTTP method to forward it to specific service
    res =
      case method do
        "GET" -> Base.get!(Serializer.attach_query_params(url, params), req_headers)
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

  # Format multipart body and set as POST HTTP method
  @spec format_post_request(String.t, map_string_upload, headers_list) :: %Plug.Conn{}
  defp format_post_request(url, %{"qqfile" => %Plug.Upload{}} = params, headers) do
    %{"qqfile" => file} = params
    optional_params = params |> Map.delete("qqfile")
    params_merged = Enum.concat(
      optional_params,
      [{:file, file.path}, {"content-type", file.content_type}, {"filename", file.filename}]
    )

    Base.post!(url, {:multipart, params_merged}, headers)
  end

  @spec format_post_request(String.t, map, headers_list) :: %Plug.Conn{}
  defp format_post_request(url, params, headers) do
    Base.post!(url, Poison.encode!(params), headers)
  end

  # Log API call to Kafka
  @spec log_to_kafka(Proxy.endpoint, Proxy.api_definition, %Plug.Conn{}) :: :ok
  defp log_to_kafka(%{"auth_type" => "jwt"}, %{"not_secured" => false} = _endpoint, _conn) do
    # TODO we need a more general logging module that takes care of things like this.
    # E.g., if logging to Kafka is disabled, a user could still want to log calls to
    # a file-based logger (like a normal access.log of a webserver).
    # Kafka.log_proxy_api_call(endpoint, conn)
    :ok
  end
  defp log_to_kafka(_api, _endpoint, _conn) do
    # no-op - we only log authenticated requests for now.
    :ok
  end

  # Send error message with unsupported HTTP method
  @spec send_response({:ok, %Plug.Conn{}, nil}) :: %Plug.Conn{}
  defp send_response({:ok, conn, nil}) do
    send_resp(conn, 405, Serializer.encode_error_message("Method is not supported"))
  end

  # Send fulfilled response back to client
  @spec send_response({:ok, %Plug.Conn{}, map}) :: %Plug.Conn{}
  defp send_response({:ok, conn, %{headers: headers, status_code: status_code, body: body}}) do
    conn = %{conn | resp_headers: headers}
    if Serializer.header_value?(conn, "transfer-encoding", "chunked") do
      send_chunked_response(conn, headers, status_code, body)
    else
      %{conn | resp_headers: headers} |> send_resp(status_code, body)
    end
  end

  # Send chunked response to client with body and set transfer-encoding
  @spec send_chunked_response(%Plug.Conn{}, headers_list, integer, String.t) :: %Plug.Conn{}
  defp send_chunked_response(conn, headers, status_code, body) do
    conn = %{conn | resp_headers: headers} |> send_chunked(status_code)
    conn |> chunk(body)
    conn
  end
end
