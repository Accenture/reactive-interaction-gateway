defmodule RigInboundGateway.ApiProxy.Router do
  @moduledoc """
  Provides middleware proxy for incoming REST requests at specific endpoints.
  Initial API definitions are loaded from Phoenix Presence under topic "proxy".
  Matches all incoming HTTP requests and checks if such endpoint is defined in any API.
  If endpoint needs authentication, it is automatically triggered.
  Valid HTTP requests are forwarded to given service and their response is sent back to client.
  """
  use Rig.Config, [:logger_modules, :active_loggers]
  use Plug.Router
  require Logger

  alias RigInboundGateway.ApiProxy.Base
  alias RigInboundGateway.ApiProxy.Auth
  alias RigInboundGateway.ApiProxy.Serializer
  alias RigInboundGateway.RateLimit
  alias RigInboundGateway.Proxy
  alias Rig.Kafka
  alias Rig.Connection.Codec

  @typep headers :: [{String.t, String.t}]
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
    String.match?(request_path, ~r/^#{full_path}$/)
  end

  # Match endpoint method against requested method
  @spec match_http_method(String.t, String.t) :: boolean
  defp match_http_method(method, request_method), do: method == request_method

  # Skip authentication if turned off
  @spec check_auth_and_forward_request(
    Proxy.endpoint, Proxy.api_definition, Plug.Conn.t) :: Plug.Conn.t
  defp check_auth_and_forward_request(%{"not_secured" => true} = endpoint, api, conn) do
    check_request_type(endpoint, api, conn)
  end
  # Skip authentication if no auth type is set
  @spec check_auth_and_forward_request(
    Proxy.endpoint, Proxy.api_definition, Plug.Conn.t) :: Plug.Conn.t
  defp check_auth_and_forward_request(endpoint, %{"auth_type" => "none"} = api, conn) do
    check_request_type(endpoint, api, conn)
  end
  # Authentication with JWT
  @spec check_auth_and_forward_request(
    Proxy.endpoint, Proxy.api_definition, Plug.Conn.t) :: Plug.Conn.t
  defp check_auth_and_forward_request(%{"not_secured" => false} = endpoint, %{"auth_type" => "jwt"} = api, conn) do
    tokens = Enum.concat(Auth.pick_query_token(conn, api), Auth.pick_header_token(conn, api))
    case Auth.any_token_valid?(tokens) do
      true -> check_request_type(endpoint, api, conn)
      false -> send_resp(conn, 401, Serializer.encode_error_message("Missing or invalid token"))
    end
  end

  defp check_request_type(%{"type" => "async", "target" => "kafka"}, _api, %{params: %{"partition_key" => partition_key,
  "data" => data}} = conn) do
    conf = config()
    message_json = data |> Poison.encode!()
    response_json = %{"msg" => "Async event successfully published.", "data" => message_json} |> Poison.encode!()

    Kafka.produce(conf.kafka_request_topic, _partition_key = partition_key, _plaintext = message_json)
    send_response({:ok, conn, %{body: response_json, status_code: 200, headers: [{"content-type", "application/json"}]}})
  end

  defp check_request_type(%{"type" => "sync", "target" => "kafka"}, _api, %{params: %{"partition_key" => partition_key,
  "data" => data}} = conn) do
    conf = config()
    serialized_pid = self() |> Codec.serialize()
    message_json =
      data
      |> Map.put("correlation_id", serialized_pid)
      |> Poison.encode!()

    Kafka.produce(conf.kafka_request_topic, _partition_key = partition_key, _plaintext = message_json)

    receive do
      {:ok, _msg} ->
        response_json = %{"msg" => "Sync event successfully published."} |> Poison.encode!()
        send_response({:ok, conn, %{body: response_json, status_code: 200, headers: [{"content-type", "application/json"}]}})
    after
      conf.kafka_request_timeout ->
        response_json = %{"msg" => "Sync event not acknowledged."} |> Poison.encode!()
        send_response({:ok, conn, %{body: response_json, status_code: 500, headers: [{"content-type", "application/json"}]}})
    end
  end

  defp check_request_type(endpoint, api, conn) do
    transform_req_headers(endpoint, api, conn)
  end

  # Transform request headers
  @spec transform_req_headers(Proxy.endpoint(), Proxy.api_definition(), Plug.Conn.t) ::
          Plug.Conn.t
  defp transform_req_headers(
         %{"transform_request_headers" => true} = endpoint,
         %{"versioned" => false} = api,
         %{req_headers: req_headers} = conn
       ) do
    %{"add_headers" => add_headers} =
      Kernel.get_in(api, ["version_data", "default", "transform_request_headers"])

    new_req_headers =
      add_headers
      |> Enum.to_list()
      |> Serializer.add_headers(req_headers)

    new_conn = conn |> Map.put(:req_headers, new_req_headers)
    forward_request(endpoint, api, new_conn)
  end

  defp transform_req_headers(
         %{"transform_request_headers" => true} = _endpoint,
         %{"versioned" => true} = _api,
         _conn
       ),
       do: raise("Not implemented - to be done when API versioning has landed.")

  defp transform_req_headers(endpoint, api, conn), do: forward_request(endpoint, api, conn)

  @spec forward_request(Proxy.endpoint, Proxy.api_definition, Plug.Conn.t) :: Plug.Conn.t
  defp forward_request(endpoint, api, conn) do
    log_request(endpoint, api, conn)

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
  @spec format_post_request(String.t, map_string_upload, headers) :: Plug.Conn.t
  defp format_post_request(url, %{"qqfile" => %Plug.Upload{}} = params, headers) do
    %{"qqfile" => file} = params
    optional_params = params |> Map.delete("qqfile")
    params_merged = Enum.concat(
      optional_params,
      [{:file, file.path}, {"content-type", file.content_type}, {"filename", file.filename}]
    )

    Base.post!(url, {:multipart, params_merged}, headers)
  end

  @spec format_post_request(String.t, map, headers) :: Plug.Conn.t
  defp format_post_request(url, params, headers) do
    Base.post!(url, Poison.encode!(params), headers)
  end

  @spec log_request(Proxy.endpoint, Proxy.api_definition, Plug.Conn.t) :: :ok
  defp log_request(endpoint, api, conn) do
    conf = config()

    conf.active_loggers
    |> Enum.each(fn
      nil -> :ignore
      "" -> :ignore
      (name) ->
        mod = Map.fetch!(conf.logger_modules, name)
        mod.log_call(endpoint, api, conn)
    end)
  end

  # Send error message with unsupported HTTP method
  @spec send_response({:ok, Plug.Conn.t, nil}) :: Plug.Conn.t
  defp send_response({:ok, conn, nil}) do
    send_resp(conn, 405, Serializer.encode_error_message("Method is not supported"))
  end

  # Send fulfilled response back to client
  @spec send_response({:ok, Plug.Conn.t, map}) :: Plug.Conn.t
  defp send_response({:ok, conn, %{headers: headers, status_code: status_code, body: body}}) do
    downcased_headers = headers |> Serializer.downcase_headers
    conn = %{conn | resp_headers: downcased_headers}

    if Serializer.header_value?(downcased_headers, "transfer-encoding", "chunked") do
      send_chunked_response(conn, status_code, body)
    else
      send_resp(conn, status_code, body)
    end
  end

  # Send chunked response to client with body and set transfer-encoding
  @spec send_chunked_response(Plug.Conn.t, integer, String.t) :: Plug.Conn.t
  defp send_chunked_response(conn, status_code, body) do
    chunked_conn = send_chunked(conn, status_code)
    chunked_conn |> chunk(body)
    chunked_conn
  end
end
