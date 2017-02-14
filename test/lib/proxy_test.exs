defmodule Gateway.Terraformers.ProxyTest do
  use Gateway.ConnCase

  test "GET /random/route", %{conn: conn} do
    conn = get conn, "/random/route"
    assert response(conn, 404) =~ "{\"message\":\"Route is not available\"}"
  end
  
  test "GET /is/user-info", %{conn: conn} do
    conn = get conn, "/is/user-info"
    assert response(conn, 401) =~ "{\"message\":\"Missing authentication\"}"
  end
  
  test "PATCH /is/auth", %{conn: conn} do
    conn = patch conn, "/is/auth"
    assert response(conn, 405) =~ "{\"message\":\"Method is not supported\"}"
  end
  
end
