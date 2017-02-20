defmodule Gateway.Terraformers.ProxyTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import Joken

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

  test "GET /is/auth should return 404 as unspported method for given route" do
    conn = call(Gateway.Router, conn(:get, "/is/auth"))
    assert conn.status == 404
    assert conn.resp_body =~ "{\"message\":\"Route is not available\"}"
  end

  test "POST /is/auth should return token", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/is/auth" == conn.request_path
      assert "POST" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"token": "123"}>)
    end
    
    conn = call(Gateway.Router, conn(:post, "/is/auth"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"token\": \"123\"}"
  end
  
  test "GET /is/user-info should verify JWT and return data", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/is/user-info" == conn.request_path
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"response": "ok"}>)
    end
    
    jwt = generate_jwt()
    conn = conn(:get, "/is/user-info") |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, conn)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\": \"ok\"}"
  end
  
  test "POST /is/user-info should verify JWT and return data", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/is/user-info" == conn.request_path
      assert "POST" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"response": "ok"}>)
    end
    
    jwt = generate_jwt()
    conn = conn(:post, "/is/user-info") |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, conn)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\": \"ok\"}"
  end
  
  test "PUT /is/users{id} should verify JWT and return data", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/is/users/mike" == conn.request_path
      assert "PUT" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"response": "ok"}>)
    end

    jwt = generate_jwt()
    conn = conn(:put, "/is/users/mike") |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, conn)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\": \"ok\"}"
  end
  
  defp generate_jwt do
    token()
      |> with_signer(hs256(Application.get_env(:gateway, Gateway.Endpoint)[:jwt_key]))
      |> sign
      |> get_compact
  end
  
  defp call(mod, conn) do
    mod.call(conn, [])
  end
end
