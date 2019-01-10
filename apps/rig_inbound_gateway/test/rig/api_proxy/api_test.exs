defmodule RigInboundGateway.ApiProxy.ApiTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias RigInboundGateway.ApiProxy.Api

  test "Without API definitions, a request never matches." do
    apis = []
    conn = %{method: "GET", request_path: "/foo"}

    assert Api.filter(apis, conn) == []
  end

  test "With a (placeholder-free) API definition in place, a request may match." do
    api1_endpoint1 = %{
      "id" => "test-endpoint",
      "type" => "http",
      "secured" => false,
      "method" => "GET",
      "path" => "/foo"
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
      "path" => "/docs/123/tables"
    }

    api1_endpoint2 = %{
      "id" => "test-endpoint-that-should-match",
      "type" => "http",
      "secured" => false,
      "method" => "GET",
      "path" => "/docs/{docId}/tables/{tableId}"
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

  test "Rewriting the request path works with paths and placeholders." do
    endpoint = %{
      "id" => "test-endpoint",
      "type" => "http",
      "method" => "GET",
      "path" => "/docs/{docId}/tables/{tableId}",
      # There are capture group references but they should have no effect here:
      "path_replacement" => ~S"/mytables/\\1/\\2"
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
    assert rewritten_path == ~S"/mytables/\1/\2"
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

  test "Given both a path and a path_regex, either one of them may cause a match." do
    endpoint_where_path_matches = %{
      "id" => "test-endpoint",
      "type" => "http",
      "method" => "GET",
      "path" => "/docs/123/tables/456",
      "path_regex" => "/some/other/regex/that/does/not/match"
    }

    endpoint_where_regex_matches = %{
      "id" => "test-endpoint",
      "type" => "http",
      "method" => "GET",
      "path" => "/some/other/path/that/does/not/match",
      "path_regex" => "/docs/[0-9]+/tables/[0-9]*"
    }

    api = %{
      "id" => "test-api",
      "name" => "Test API",
      "version_data" => %{
        "default" => %{
          "endpoints" => [endpoint_where_path_matches, endpoint_where_regex_matches]
        }
      },
      "proxy" => %{
        "target_url" => "localhost",
        "port" => 1234
      }
    }

    conn = %{method: "GET", request_path: "/docs/123/tables/456"}

    assert [
             {^api, ^endpoint_where_path_matches, "/docs/123/tables/456"},
             {^api, ^endpoint_where_regex_matches, "/docs/123/tables/456"}
           ] = Api.filter([api], conn)
  end
end
