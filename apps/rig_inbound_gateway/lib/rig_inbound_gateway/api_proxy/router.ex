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

  alias RigInboundGateway.ApiProxy.Api
  alias RigInboundGateway.ApiProxy.Auth
  alias RigInboundGateway.ApiProxy.Handler.Http, as: HttpHandler
  alias RigInboundGateway.ApiProxy.Handler.Kafka, as: KafkaHandler
  alias RigInboundGateway.ApiProxy.Handler.Kinesis, as: KinesisHandler
  alias RigInboundGateway.ApiProxy.Serializer
  alias RigInboundGateway.Proxy
  alias RigMetrics.ProxyMetrics

  plug(:match)
  plug(:dispatch)

  # Get all incoming HTTP requests, check if they are valid, provide authentication if needed
  match _ do
    active_apis =
      Proxy
      |> Proxy.list_apis()
      |> Enum.map(fn {_key, api} -> api end)
      |> Enum.filter(fn api -> api["active"] == true end)

    matches = Api.filter(active_apis, conn)

    case matches do
      [] ->
        ProxyMetrics.count_proxy_request(
          conn.method,
          conn.request_path,
          "N/A",
          "N/A",
          "not_found"
        )

        send_resp(conn, :not_found, Serializer.encode_error_message(:not_found))

      [{api, endpoint, request_path} | other_matches] ->
        if other_matches != [] do
          Logger.warn(fn -> "Multiple API definitions for %{conn.method} %{conn.request_path}" end)
        end

        proxy_request(conn, api, endpoint, request_path)
    end
  end

  # ---

  defp proxy_request(conn, api, endpoint, request_path) do
    with :ok <- Auth.check(conn, api, endpoint),
         conn <- transform_req_headers(conn, api, endpoint) do
      target = Map.get(endpoint, "target", "http") |> String.downcase()

      handler =
        case target do
          "http" -> HttpHandler
          "kafka" -> KafkaHandler
          "kinesis" -> KinesisHandler
        end

      %{active_loggers: active_loggers, logger_modules: logger_modules} = config()

      Enum.each(active_loggers, fn l ->
        ll = Map.get(logger_modules, l)

        ll.log_call(
          endpoint,
          api,
          conn
        )
      end)

      handler.handle_http_request(conn, api, endpoint, request_path)
    else
      {:error, :authentication_failed} -> send_resp(conn, :unauthorized, "Authentication failed.")
    end
  end

  # ---

  defp transform_req_headers(conn, api, endpoint)

  defp transform_req_headers(
         conn,
         %{"versioned" => false} = api,
         %{"transform_request_headers" => true}
       ) do
    %{"add_headers" => additional_headers} =
      get_in(api, ["version_data", "default", "transform_request_headers"])

    req_header_map = Map.new(conn.req_headers)

    merged_req_headers =
      req_header_map
      |> Map.merge(additional_headers)
      |> Enum.to_list()

    conn
    |> Map.put(:req_headers, merged_req_headers)
  end

  defp transform_req_headers(conn, _, _), do: conn
end
