defmodule RigInboundGateway.ApiProxy.AuthTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use RigInboundGatewayWeb.ConnCase

  alias RigInboundGateway.ApiProxy.Auth

  test "pick_query_token should return token when API wants it" do
    conn = conn_with_query(%{"token" => "JWT"})
    api = %{"auth" => %{"use_query" => true, "query_name" => "token"}}
    assert Auth.pick_query_token(conn, api) == ["JWT"]
  end

  test "pick_query_token shouldn\'t return token when API don\'t want it" do
    conn = conn_with_query(%{"token" => "JWT"})
    api = %{"auth" => %{"use_query" => false}}
    assert Auth.pick_query_token(conn, api) == [""]
  end

  test "pick_header_token should return token when API wants it" do
    conn = conn_with_header("authorization", "JWT")
    api = %{"auth" => %{"use_header" => true, "header_name" => "authorization"}}
    assert Auth.pick_header_token(conn, api) == ["JWT"]
  end

  test "pick_header_token should work also with capital letters" do
    conn = conn_with_header("authorization", "JWT")
    api = %{"auth" => %{"use_header" => true, "header_name" => "Authorization"}}
    assert Auth.pick_header_token(conn, api) == ["JWT"]
  end

  test "pick_header_token shouldn\'t return token when API don\'t want it" do
    conn = conn_with_header("authorization", "JWT")
    api = %{"auth" => %{"use_header" => false}}
    assert Auth.pick_header_token(conn, api) == [""]
  end

  test "any_token_valid should return true on valid JWT" do
    jwt = generate_jwt()
    assert Auth.any_token_valid?([jwt]) == true
  end

  test "any_token_valid should return false on invalid JWT" do
    assert Auth.any_token_valid?(["JWT"]) == false
  end

  defp conn_with_header(key, value) do
    %Plug.Conn{} |> put_req_header(key, value)
  end

  defp conn_with_query(query_params) do
    %Plug.Conn{:query_params => query_params}
  end

end
