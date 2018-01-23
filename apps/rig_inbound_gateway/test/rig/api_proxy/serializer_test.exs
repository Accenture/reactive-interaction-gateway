defmodule RigInboundGateway.ApiProxy.SerializerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use RigInboundGatewayWeb.ConnCase

  alias RigInboundGateway.ApiProxy.Serializer

  test "encode_error_message should encode to JSON format" do
    assert Serializer.encode_error_message("OK") =~ "{\"message\":\"OK\"}"
  end

  test "build_url should build URL from env var if API wants it" do
    proxy = %{"use_env" => true, "target_url" => "SOME_HOST", "port" => 8080}
    assert Serializer.build_url(proxy, "/something") == "localhost:8080/something"
  end

  test "build_url should build URL without env var if API don'\t want it" do
    proxy = %{"use_env" => false, "target_url" => "http://example.com", "port" => 80}
    assert Serializer.build_url(proxy, "/something") == "http://example.com:80/something"
  end

  test "attach_query_params should not attach query params if not present" do
    assert Serializer.attach_query_params("http://example.com", %{}) == "http://example.com"
  end

  test "attach_query_params should attach query params if present" do
    assert Serializer.attach_query_params("http://example.com", %{"a" => "b"}) == "http://example.com?a=b"
  end

  test "header_value? should return true if headers have key with given value" do
    conn = conn_with_header("a", "b")
    assert Serializer.header_value?(conn, "a", "b") == true
  end

  test "header_value? should handle capital letters" do
    conn = conn_with_header("A", "b")
    assert Serializer.header_value?(conn, "a", "b") == true
  end

  test "header_value? should return false if headers don'\t have key with given value" do
    conn = conn_with_header("a", "b")
    assert Serializer.header_value?(conn, "a", "bb") == false
  end

  defp conn_with_header(key, value) do
    %Plug.Conn{} |> put_resp_header(key, value)
  end

end
