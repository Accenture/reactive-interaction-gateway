defmodule RigInboundGateway.ApiProxy.ApiTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias RigInboundGateway.ApiProxy.Api

  test "Without API definitions, a request never matches." do
    apis = []
    conn = %{method: "GET", request_path: "/foo"}

    assert Api.filter(apis, conn) == []
  end

  test "With a simple path regex API definition in place, a request may match." do
    api1_endpoint1 = %{
      "id" => "test-endpoint",
      "type" => "http",
      "secured" => false,
      "method" => "GET",
      "path_regex" => "/foo"
    }

    api1 = %{
      "id" => "test-api",
      "name" => "Test API",
      "version_data" => %{
        "default" => %{
          "endpoints" => [api1_endpoint1]
        }
      },
      "proxy" => %{
        "target_url" => "localhost",
        "port" => 1234
      }
    }

    apis = [api1]
    conn = %{method: "GET", request_path: "/foo"}

    assert Api.filter(apis, conn) == [{api1, api1_endpoint1, "/foo"}]
  end

  test "An API definition that uses placeholders may match a request." do
    api1_endpoint1 = %{
      "id" => "test-endpoint-that-should-not-match",
      "type" => "http",
      "secured" => false,
      "method" => "GET",
      "path_regex" => "/docs/123/tables"
    }

    api1_endpoint2 = %{
      "id" => "test-endpoint-that-should-match",
      "type" => "http",
      "secured" => false,
      "method" => "GET",
      "path_regex" => "/docs/(.+)/tables/(.+)"
    }

    api1 = %{
      "id" => "test-api",
      "name" => "Test API",
      "version_data" => %{
        "default" => %{
          "endpoints" => [api1_endpoint1, api1_endpoint2]
        }
      },
      "proxy" => %{
        "target_url" => "localhost",
        "port" => 1234
      }
    }

    apis = [api1]
    conn = %{method: "GET", request_path: "/docs/123/tables/456"}

    assert Api.filter(apis, conn) == [{api1, api1_endpoint2, "/docs/123/tables/456"}]
  end

  test "Rewriting the request path works using a path regex pattern." do
    endpoint = %{
      "id" => "test-endpoint",
      "type" => "http",
      "method" => "GET",
      "path_regex" => "/docs/([^/]+)/tables/([^/]+)",
      # In this case the capture group references should be in effect:
      "path_replacement" => ~S"/mytables/\1/\2"
    }

    api = %{
      "id" => "test-api",
      "name" => "Test API",
      "version_data" => %{
        "default" => %{
          "endpoints" => [endpoint]
        }
      },
      "proxy" => %{
        "target_url" => "localhost",
        "port" => 1234
      }
    }

    conn = %{method: "GET", request_path: "/docs/123/tables/456"}

    assert [{^api, ^endpoint, rewritten_path}] = Api.filter([api], conn)
    assert rewritten_path == "/mytables/123/456"
  end
end
