defmodule RigAuth.Jwt.PlugTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Plug.Test
  use RigAuth.ConnCase

  test "should return 200 status for authorized /v1/users request" do
    conn =
      setup_conn("GET", "/v1/users", ["getSessions"])
      |> RigAuth.Jwt.Plug.call(%{})
      |> send_resp(200, "[]")
    assert response(conn, 200) =~ "[]"
  end

  test "should return 403 status for unauthorized /v1/users request" do
    conn =
      setup_conn("GET", "/v1/users")
      |> RigAuth.Jwt.Plug.call(%{})
      |> send_resp(200, "[]")
    assert response(conn, 403) =~ "{\"msg\":\"Unauthorized\"}"
  end

  test "should return 200 status for authorized /v1/users/123/sessions request" do
    conn =
      setup_conn("GET", "/v1/users/123/sessions", ["getSessionConnections"])
      |> RigAuth.Jwt.Plug.call(%{})
      |> send_resp(200, "[]")
    assert response(conn, 200) =~ "[]"
  end

  test "should return 403 status for unauthorized /v1/users/123/sessions request" do
    conn =
      setup_conn("GET", "/v1/users/123/sessions")
      |> RigAuth.Jwt.Plug.call(%{})
      |> send_resp(200, "[]")
    assert response(conn, 403) =~ "{\"msg\":\"Unauthorized\"}"
  end

  test "should return 204 status for authorized /v1/users/123/sessions/abc123 request" do
    conn =
      setup_conn("DELETE", "/v1/users/123/sessions/abc123", ["deleteConnection"])
      |> RigAuth.Jwt.Plug.call(%{})
      |> send_resp(204, "{}")
    assert response(conn, 204) =~ "{}"
  end

  test "should return 403 status for unauthorized /v1/users/123/sessions/abc123 request" do
    conn =
      setup_conn("DELETE", "/v1/users/123/sessions/abc123")
      |> RigAuth.Jwt.Plug.call(%{})
      |> send_resp(200, "[]")
    assert response(conn, 403) =~ "{\"msg\":\"Unauthorized\"}"
  end
end
