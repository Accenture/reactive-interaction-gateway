defmodule Gateway.ApiProxy.Proxy do
  @moduledoc """
  Provides middleware proxy for incoming REST requests at specific routes.
  Matches all incoming HTTP requests and checks if such route is defined in json file.
  If route needs authentication it is automatically triggered.
  Valid HTTP requests are forwarded to given service an their response is sent back to client.
  """
  use Plug.Router

  alias Plug.Conn.Query
  alias Gateway.ApiProxy.Base
  alias Gateway.Utils.Jwt

  plug :match
  plug :dispatch

  # Get all incoming HTTP requests, check if they are valid, provide authentication if needed
  match _ do
    %{method: method, request_path: request_path} = conn

    :gateway
    |> Application.fetch_env!(:proxy_route_config)
    |> File.read!
    |> Poison.decode!
    |> Enum.find(fn(route) ->
      match_path(route, request_path) && match_http_method(route, method)
    end)
    |> authenticate_request(conn)
  end

  # Match route path against requested path
  @spec match_path(map, String.t) :: boolean
  defp match_path(route, request_path) do
    # Replace wildcards with actual params
    replace_wildcards = String.replace(route["path"], "{id}", ".*")
    # Match requested path against regex
    String.match?(request_path, ~r/#{replace_wildcards}$/)
  end

  # Match route method against requested method
  @spec match_http_method(map, String.t) :: boolean
  defp match_http_method(route, method), do: route["method"] == method

  # Encode custom error messages with Poison to JSON format
  @type json_message :: %{message: String.t}
  @spec encode_error_message(String.t) :: json_message
  defp encode_error_message(message) do
    Poison.encode!(%{message: message})
  end

  # Handle unsupported route
  @spec authenticate_request(nil, map) :: map
  defp authenticate_request(nil, conn) do
    send_resp(conn, 404, encode_error_message("Route is not available"))
  end

  # Authentication required
  @spec authenticate_request(map, map) :: map
  defp authenticate_request(service = %{"auth" => true}, conn) do
    process_authentication(service, conn)
  end

  # Authentication not required
  defp authenticate_request(service = %{"auth" => false}, conn) do
    forward_request(service, conn)
  end

  @spec process_authentication(String.t, map) :: map
  defp process_authentication(service, conn) do
    # Get authorization form request header
    jwt = get_req_header(conn, "authorization")

    if authenticated?(jwt) do
      forward_request(service, conn)
    else
      send_resp(conn, 401, encode_error_message("Missing or invalid token"))
    end
  end

  # Authentication failed if JWT in not provided
  @spec authenticated?([]) :: false
  defp authenticated?([]), do: false
  # Validate present JWT
  @spec authenticated?(tuple) :: boolean
  defp authenticated?(jwt) do
    jwt
    |> List.first
    |> Jwt.valid?
  end

  @spec forward_request(map, map) :: map
  defp forward_request(service, conn) do
    %{
      method: method,
      request_path: request_path,
      params: params,
      req_headers: req_headers
    } = conn
    # Build URL
    url = build_url(service, request_path)

    # Match URL against HTTP method to forward it to specific service
    res =
      case method do
        "GET" -> Base.get!(attachQueryParams(url, params), req_headers)
        "POST" -> Base.post!(url, Poison.encode!(params), req_headers)
        "PUT" -> Base.put!(url, Poison.encode!(params), req_headers)
        "DELETE" -> Base.delete!(url, req_headers)
        _ -> nil
      end

    send_response({:ok, conn, res})
  end

  # Builds URL where REST request should be proxied
  @spec build_url(map, String.t) :: String.t
  defp build_url(service, request_path) do
    host = System.get_env(service["host"]) || "localhost"
    "#{host}:#{service["port"]}#{request_path}"
  end

  # Workaround for HTTPoison/URI.encode not supporting nested query params
  @spec attachQueryParams(String.t, nil) :: String.t
  defp attachQueryParams(url, nil), do: url

  @spec attachQueryParams(String.t, map) :: String.t
  defp attachQueryParams(url, params) do
    url <> "?" <> Query.encode(params)
  end

  # Function for sending response back to client
  @spec send_response({:ok, map, nil}) :: map
  defp send_response({:ok, conn, nil}) do
    send_resp(conn, 405, encode_error_message("Method is not supported"))
  end

  @spec send_response({:ok, map, map}) :: map
  defp send_response({:ok, conn, %{headers: headers, status_code: status_code, body: body}}) do
    %{conn | resp_headers: headers} |> send_resp(status_code, body)
  end

end
