defmodule Rig.ConfigTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Rig.Config
  alias RigInboundGateway.ProxyConfig

  test "parse_json_env should uppercase HTTP method" do
    lowercase_endpoints = [
      %{
        "id" => "1",
        "method" => "get",
        "path" => "/foo"
      }
    ]

    uppercase_endpoints = [
      %{
        "id" => "1",
        "method" => "GET",
        "path" => "/foo"
      }
    ]

    lowercase_api = ProxyConfig.create_proxy_config("uppercase", lowercase_endpoints)
    uppercase_api = ProxyConfig.create_proxy_config("uppercase", uppercase_endpoints)
    proxy = Jason.encode!([lowercase_api])

    {:ok, config} = Config.parse_json_env(proxy)
    assert config == [uppercase_api]
  end

  test "parse_json_env should return %SyntaxError{} when JSON is not valid" do
    assert {:error, %Config.SyntaxError{}} = Config.parse_json_env("./doesnotexist.json")
  end
end
