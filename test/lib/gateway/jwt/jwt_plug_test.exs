defmodule Gateway.JwtPlugTest do
  use Gateway.ConnCase

  test "should return 200 status for authorized /rg/sessions request" do
    conn =
      setup_conn(["getSessions"])
      |> get("/rg/sessions")
    assert response(conn, 200) =~ "[]"
  end

  test "should return 403 status for unauthorized /rg/sessions request" do
    conn =
      setup_conn()
      |> get("/rg/sessions")
    assert response(conn, 403) =~ "{\"msg\":\"Unauthorized\"}"
  end

  test "should return 200 status for authorized /rg/sessions/123 request" do
    conn =
      setup_conn(["getSessionConnections"])
      |> get("/rg/sessions/123")
    assert response(conn, 200) =~ "[]"
  end

  test "should return 403 status for unauthorized /rg/sessions/123 request" do
    conn =
      setup_conn()
      |> get("/rg/sessions/123")
    assert response(conn, 403) =~ "{\"msg\":\"Unauthorized\"}"
  end

  test "should return 404 status for authorized /rg/connections/abc123 request, but wrong jti" do
    conn =
      setup_conn(["deleteConnection"])
      |> delete("/rg/connections/abc123")
    assert response(conn, 404) =~ "{}"
  end

  test "should return 403 status for unauthorized /rg/connections/abc123 request" do
    conn =
      setup_conn()
      |> delete("/rg/connections/abc123")
    assert response(conn, 403) =~ "{\"msg\":\"Unauthorized\"}"
  end
end
