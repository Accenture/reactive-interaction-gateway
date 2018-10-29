defmodule RigInboundGateway.ApiProxy.Handler.HttpTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use RigInboundGatewayWeb.ConnCase

  alias Plug.Conn.Query

  alias RigInboundGateway.ApiProxy.Handler.Http, as: HttpHandler

  describe "build_url" do
    test "uses target_url as-is if use_env is false." do
      proxy = %{"use_env" => false, "target_url" => "https://example.com", "port" => 81}
      assert HttpHandler.build_url(proxy, "/something") == "https://example.com:81/something"
    end

    test "interpolates the target_url using env vars if use_env is true." do
      proxy = %{"use_env" => true, "target_url" => "SOME_HOST", "port" => 8080}
      assert HttpHandler.build_url(proxy, "/something") == "http://localhost:8080/something"
    end
  end

  describe "add_query_params" do
    test "does not change a URL if no params are added." do
      uri = "https://myhost.example.com/path?a=b&b=c"
      assert HttpHandler.add_query_params(uri, %{}) == uri
    end

    test "adds new query params." do
      uri = "https://myhost.example.com/path?a=b&b=c"
      new_uri = HttpHandler.add_query_params(uri, %{"c" => "d"})
      assert Query.decode(URI.parse(new_uri).query) == %{"a" => "b", "b" => "c", "c" => "d"}
    end

    test "replaces existing query params." do
      uri = "https://myhost.example.com/path?a=b&b=c"
      new_uri = HttpHandler.add_query_params(uri, %{"a" => "z"})
      assert Query.decode(URI.parse(new_uri).query) == %{"a" => "z", "b" => "c"}
    end
  end
end
