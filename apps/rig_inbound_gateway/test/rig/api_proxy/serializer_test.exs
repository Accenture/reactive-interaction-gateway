defmodule RigInboundGateway.ApiProxy.SerializerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use RigInboundGatewayWeb.ConnCase

  alias RigInboundGateway.ApiProxy.Serializer

  test "encode_error_message should encode to JSON format" do
    assert Serializer.encode_error_message("OK") =~ "{\"message\":\"OK\"}"
  end

  describe "build_url" do
    test "uses target_url as-is if use_env is false." do
      proxy = %{"use_env" => false, "target_url" => "https://example.com", "port" => 81}
      assert Serializer.build_url(proxy, "/something") == "https://example.com:81/something"
    end

    test "interpolates the target_url using env vars if use_env is true." do
      proxy = %{"use_env" => true, "target_url" => "SOME_HOST", "port" => 8080}
      assert Serializer.build_url(proxy, "/something") == "http://localhost:8080/something"
    end
  end

  test "attach_query_params should not attach query params if not present" do
    assert Serializer.attach_query_params("http://example.com", %{}) == "http://example.com"
  end

  test "attach_query_params should attach query params if present" do
    assert Serializer.attach_query_params("http://example.com", %{"a" => "b"}) ==
             "http://example.com?a=b"
  end

  test "header_value? should return true if headers have key with given value" do
    assert Serializer.header_value?([{"a", "b"}, {"d", "d"}], "a", "b") == true
  end

  test "header_value? should return false if headers don'\t have key with given value" do
    assert Serializer.header_value?([{"a", "b"}, {"d", "d"}], "a", "bb") == false
  end

  test "header_value? should not mix up searched key and value" do
    assert Serializer.header_value?([{"a", "b"}], "a", "a") == false
  end

  test "down_case_headers should down case keys for all headers" do
    assert Serializer.downcase_headers([{"A", "b"}, {"C", "d"}]) == [{"a", "b"}, {"c", "d"}]
  end

  test "add_headers should add non-existing headers" do
    assert Serializer.add_headers([{"c", "d"}, {"e", "f"}], [{"a", "b"}]) == [
             {"a", "b"},
             {"c", "d"},
             {"e", "f"}
           ]
  end

  test "add_headers should replace existing headers" do
    assert Serializer.add_headers([{"c", "d"}, {"e", "f"}], [{"a", "b"}, {"c", "X"}]) == [
             {"a", "b"},
             {"c", "d"},
             {"e", "f"}
           ]
  end
end
