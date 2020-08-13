defmodule RigTests.Proxy.ResponseFrom.AsyncHttpTest do
  @moduledoc """
  If `response_from` is set to http_async, the response is taken from internal HTTP endpoint /v3/responses

  Note that `test_with_server` sets up an HTTP server mock, which is then configured
  using the `route` macro.
  """
  # cause FakeServer opens a port:
  use ExUnit.Case, async: false

  import FakeServer
  import Plug.Conn, only: [put_req_header: 3]
  import Phoenix.ConnTest, only: [post: 3, build_conn: 0]

  alias FakeServer.Response
  alias RigInboundGateway.ApiProxyInjection

  @endpoint RigApi.Endpoint
  @api_port Confex.fetch_env!(:rig, RigApi.Endpoint)[:http][:port]
  @proxy_port Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:http][:port]

  setup_all do
    ApiProxyInjection.set()

    on_exit(fn ->
      ApiProxyInjection.restore()
    end)
  end

  test_with_server "Given response_from is set to http_async and response is in binary mode, the http response is taken from the internal HTTP endpoint." do
    test_name = "proxy-http-response-from-http-internal-binary"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      build_conn()
      |> put_req_header("rig-correlation", correlation_id)
      |> put_req_header("rig-response-code", "201")
      |> put_req_header("content-type", "application/json;charset=utf-8")
      |> post("/v3/responses", Jason.encode!(async_response))

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v3/apis"
    rig_proxy_url = "http://localhost:#{@proxy_port}"

    body =
      Jason.encode!(%{
        id: api_id,
        name: "Mock API",
        version_data: %{
          default: %{
            endpoints: [
              %{
                id: endpoint_id,
                method: "GET",
                path: endpoint_path,
                response_from: "http_async"
              }
            ]
          }
        },
        proxy: %{
          target_url: "localhost",
          port: FakeServer.port()
        }
      })

    headers = [{"content-type", "application/json"}]
    HTTPoison.post!(rig_api_url, body, headers)

    # The client calls the proxy endpoint:
    request_url = rig_proxy_url <> endpoint_path

    %HTTPoison.Response{status_code: res_status, body: res_body, headers: headers} =
      HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 201
    # ...extra headers are present
    assert Enum.member?(headers, {"content-type", "application/json;charset=utf-8"})
    # ...but the client got the response sent to the HTTP internal endpoint:
    assert Jason.decode!(res_body) == async_response
  end

  test_with_server "Given response_from is set to http_async and response code is incorrect, the calling service should receive 400 and originating request should timeout." do
    test_name = "proxy-http-response-from-http-internal-binary-timeout"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      %Plug.Conn{status: res_status, resp_body: res_body} =
        build_conn()
        |> put_req_header("rig-correlation", correlation_id)
        |> put_req_header("rig-response-code", "abc201")
        |> put_req_header("content-type", "application/json;charset=utf-8")
        |> post("/v3/responses", Jason.encode!(async_response))

      assert res_status == 400
      assert res_body == "Failed to parse request body: {:error, {:not_an_integer, \"abc201\"}}"

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v3/apis"
    rig_proxy_url = "http://localhost:#{@proxy_port}"

    body =
      Jason.encode!(%{
        id: api_id,
        name: "Mock API",
        version_data: %{
          default: %{
            endpoints: [
              %{
                id: endpoint_id,
                method: "GET",
                path: endpoint_path,
                response_from: "http_async"
              }
            ]
          }
        },
        proxy: %{
          target_url: "localhost",
          port: FakeServer.port()
        }
      })

    headers = [{"content-type", "application/json"}]
    HTTPoison.post!(rig_api_url, body, headers)

    # The client calls the proxy endpoint:
    request_url = rig_proxy_url <> endpoint_path

    assert catch_error(HTTPoison.get!(request_url)) == %HTTPoison.Error{id: nil, reason: :timeout}

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
  end
end
