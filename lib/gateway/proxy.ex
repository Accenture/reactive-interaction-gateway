defmodule Gateway.Terraformers.Proxy do
  @moduledoc """
  Provides middleware proxy for incoming REST requests at specific routes.
  """
  use Plug.Router
  import Joken
  alias Gateway.Clients.Proxy
  alias Mix.Config

  plug :match
  plug :dispatch

  match _ do
    %{request_path: request_path} = conn
    # Load proxy config
    proxy = Config.read!("config/proxy.exs")
    # Get list of routes
    routes = elem(Enum.at(elem(List.first(proxy), 1), 0), 1)
    # Find match of request path in proxy routes
    service = Enum.find(routes, fn(route) ->
      # Replace wildcards with regex words
      replace_wildcards = String.replace(route.path, "{id}", "\\w*")
      # Match requested path against regex
      String.match?(request_path, ~r/#{replace_wildcards}$/)
    end)
    # Authenticate request if needed
    authenticate_request(service, conn)
  end

  # Encode custom error messages with Poison to JSON format
  defp encode_error_message(message) do
    Poison.encode!(%{message: message})
  end

  # Handle unsupported route
  defp authenticate_request(nil, conn) do
    send_resp(conn, 404, encode_error_message("Route is not available"))
  end
  # Check route authentication and forward
  defp authenticate_request(service, conn) do
    case service.auth do
      true -> process_authentication(service, conn)
      false -> forward_request(service, conn)
    end
  end

  defp process_authentication(service, conn) do
    # Get request headers
    %{req_headers: req_headers} = conn
    # Search for authorization token
    jwt = Enum.find(req_headers, fn(item) -> elem(item, 0) == "authorization" end)
    case is_authenticated(jwt) do
      true -> forward_request(service, conn)
      false -> send_resp(conn, 401, encode_error_message("Missing authentication"))
    end
  end

  # Authentication failed if JWT in not provided
  defp is_authenticated(nil), do: false
  # Verify JWT
  defp is_authenticated(jwt) do
    # Get value for JWT from tuple
    jwt_value = elem(jwt, 1)
    # Verify JWT with Joken
    joken_map =
    jwt_value
    |> token
    |> with_validation("exp", &(&1 > current_time()))
    |> with_signer(hs256(Application.get_env(:gateway, Gateway.Endpoint)[:jwt_key]))
    |> verify
    # Check if any error occurred
    Map.get(joken_map, :errors) == []
  end

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
        "GET" -> Proxy.get!(url, req_headers, [params: Map.to_list(params)])
        "POST" -> Proxy.post!(url, Poison.encode!(params), req_headers)
        "PUT" -> Proxy.put!(url, Poison.encode!(params), req_headers)
        "DELETE" -> Proxy.delete!(url, Poison.encode!(params), req_headers)
        _ -> nil
      end

    send_response({:ok, conn, res})
  end

  # Builds URL where REST request should be proxied
  defp build_url(service, request_path) do
    host = System.get_env(service.host) || "localhost"
    "#{host}:#{service.port}#{request_path}"
  end

  # Function for sending response back to client
  defp send_response({:ok, conn, nil}) do
    send_resp(conn, 405, encode_error_message("Method is not supported"))
  end
  defp send_response({:ok, conn, %{headers: headers, status_code: status_code, body: body}}) do
    conn = %{conn | resp_headers: headers}
    send_resp(conn, status_code, body)
  end

end
