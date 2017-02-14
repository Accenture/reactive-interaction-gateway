defmodule Gateway.Terraformers.ProxyTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup do
    bypass = Bypass.open(port: 7070)
    {:ok, bypass: bypass}
  end

  test "GET /random/route should return 404 as non existing route" do
    conn = call(Gateway.Router, conn(:get, "/random/route"))
    assert conn.status == 404
    assert conn.resp_body =~ "{\"message\":\"Route is not available\"}"
  end
  
  test "GET /is/user-info should return 401 for invalid JWT" do
    conn = call(Gateway.Router, conn(:get, "/is/user-info"))
    assert conn.status == 401
    assert conn.resp_body =~ "{\"message\":\"Missing authentication\"}"
  end
  
  test "PATCH /is/auth shoudl return 405 for unsupported HTTP method" do
    conn = call(Gateway.Router, conn(:patch, "/is/auth"))
    assert conn.status == 405
    assert conn.resp_body =~ "{\"message\":\"Method is not supported\"}"
  end

  test "GET /is/auth should return token", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/is/auth" == conn.request_path
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"token": "123"}>)
    end
    conn = call(Gateway.Router, conn(:get, "/is/auth"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"token\": \"123\"}"
  end
  
  defp call(mod, conn) do
    mod.call(conn, [])
  end
end
