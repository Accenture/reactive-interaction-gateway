defmodule RigTests.Proxy.ResponseFrom.AsyncHttpTest do
  @moduledoc """
  If `response_from` is set to http_async, the response is taken from internal HTTP endpoint /v2/responses

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

  test_with_server "Given response_from is set to http_async, the http response is taken from the internal HTTP endpoint." do
    test_name = "proxy-http-response-from-http-internal"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      message =
        Jason.encode!(%{
          rig: %{correlation: correlation_id},
          body: Jason.encode!(async_response)
        })

      build_conn()
      |> put_req_header("content-type", "application/json;charset=utf-8")
      |> post("/v2/responses", message)

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                type: "http",
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
    %HTTPoison.Response{status_code: res_status, body: res_body} = HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 200
    # ...but the client got the response sent to the HTTP internal endpoint:
    assert Jason.decode!(res_body) == async_response
  end

  test_with_server "Given response_from is set to http_async and response is in binary mode, the http response should include only body content." do
    test_name = "proxy-http-response-from-http-internal-binary"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      build_conn()
      |> put_req_header("rig-correlation", correlation_id)
      |> put_req_header("content-type", "application/json;charset=utf-8")
      |> post("/v2/responses", Jason.encode!(async_response))

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                type: "http",
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
    %HTTPoison.Response{status_code: res_status, body: res_body} = HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 200
    # ...but the client got the response sent to the HTTP internal endpoint:
    assert Jason.decode!(res_body) == async_response
  end

  test_with_server "Given response_from is set to http_async, the custom http response code - 201 - is taken from the internal HTTP endpoint." do
    test_name = "proxy-http-response-from-http-internal-status-code"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      message =
        Jason.encode!(%{
          rig: %{correlation: correlation_id, response_code: 201},
          body: Jason.encode!(async_response)
        })

      build_conn()
      |> put_req_header("content-type", "application/json;charset=utf-8")
      |> post("/v2/responses", message)

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                type: "http",
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
    %HTTPoison.Response{status_code: res_status, body: res_body} = HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 201
    # ...but the client got the response sent to the HTTP internal endpoint:
    assert Jason.decode!(res_body) == async_response
  end

  test_with_server "Given response_from is set to http_async, the provided headers are taken from the internal HTTP endpoint." do
    test_name = "proxy-http-response-from-http-internal-headers"

    api_id = "mock-#{test_name}-api"
    endpoint_id = "mock-#{test_name}-endpoint"
    endpoint_path = "/#{endpoint_id}"
    sync_response = %{"this response" => "the client never sees this response"}
    async_response = %{"message" => "this is the async response that reaches the client instead"}

    route(endpoint_path, fn %{query: %{"correlation" => correlation_id}} ->
      message =
        Jason.encode!(%{
          rig: %{correlation: correlation_id, response_code: 201},
          body: Jason.encode!(async_response),
          headers: %{foo: "bar"}
        })

      IO.inspect(message, label: "message")

      build_conn()
      |> put_req_header("content-type", "application/json;charset=utf-8")
      |> post("/v2/responses", message)

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                type: "http",
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

    %HTTPoison.Response{status_code: res_status, body: res_body, headers: res_headers} =
      HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 201
    # ...but the client got the response sent to the HTTP internal endpoint:
    assert Jason.decode!(res_body) == async_response
    assert Enum.member?(res_headers, {"foo", "bar"})
  end

  test_with_server "Given response_from is set to http_async and response is in binary mode, the custom http response code - 201 - is taken from the internal HTTP endpoint." do
    test_name = "proxy-http-response-from-http-internal-binary-status-code"

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
      |> post("/v2/responses", Jason.encode!(async_response))

      Response.ok!(sync_response, %{"content-type" => "application/json"})
    end)

    # We register the endpoint with the proxy:
    rig_api_url = "http://localhost:#{@api_port}/v2/apis"
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
                type: "http",
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
    %HTTPoison.Response{status_code: res_status, body: res_body} = HTTPoison.get!(request_url)

    # Now we can assert that...
    # ...the fake backend service has been called:
    assert FakeServer.hits() == 1
    # ...the connection is closed and the status is OK:
    assert res_status == 201
    # ...but the client got the response sent to the HTTP internal endpoint:
    assert Jason.decode!(res_body) == async_response
  end
end
