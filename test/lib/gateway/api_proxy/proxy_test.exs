defmodule Gateway.ApiProxy.ProxyTest do
  use ExUnit.Case, async: true
  use Gateway.ConnCase
  import Joken

  setup do
    first_service = Bypass.open(port: 7070)
    second_service = Bypass.open(port: 8080)
    third_service = Bypass.open(port: 8889)

    {:ok, 
      first_service: first_service,
      second_service: second_service,
      third_service: third_service
    }
  end

  test "GET /random/route should return 404 as non existing route" do
    conn = call(Gateway.Router, build_conn(:get, "/random/route"))
    assert conn.status == 404
    assert conn.resp_body =~ "{\"message\":\"Route is not available\"}"
  end

  test "GET /is/user-info should return 401 for invalid JWT" do
    conn = call(Gateway.Router, build_conn(:get, "/is/user-info"))
    assert conn.status == 401
    assert conn.resp_body =~ "{\"message\":\"Missing or invalid token\"}"
  end

  test "GET /is/auth should return 404 as unspported method for given route" do
    conn = call(Gateway.Router, build_conn(:get, "/is/auth"))
    assert conn.status == 404
    assert conn.resp_body =~ "{\"message\":\"Route is not available\"}"
  end

  test "POST /is/auth should return token", %{first_service: first_service} do
    Bypass.expect first_service, fn conn ->
      assert "/is/auth" == conn.request_path
      assert "POST" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"token": "123"}>)
    end

    conn = call(Gateway.Router, build_conn(:post, "/is/auth"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"token\": \"123\"}"
  end
  
  test "GET /is/user-info should verify JWT and return data", %{first_service: first_service} do
    Bypass.expect first_service, fn conn ->
      assert "/is/user-info" == conn.request_path
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"response": "ok"}>)
    end

    jwt = generate_jwt()
    request = build_conn(:get, "/is/user-info") |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\": \"ok\"}"
  end

  test "POST /is/user-info should verify JWT and return data", %{first_service: first_service} do
    Bypass.expect first_service, fn conn ->
      assert "/is/user-info" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, _conn} = Plug.Conn.read_body(conn)
      assert body == "{\"status\":\"ok\"}"
      Plug.Conn.resp(conn, 200, ~s<{"response": "ok"}>)
    end

    jwt = generate_jwt()
    request = build_conn(:post, "/is/user-info", %{"status" => "ok"}) |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\": \"ok\"}"
  end

  test "PUT /is/users/{id} should verify JWT and return data", %{first_service: first_service} do
    Bypass.expect first_service, fn conn ->
      assert "/is/users/mike" == conn.request_path
      assert "PUT" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"response": "ok"}>)
    end

    jwt = generate_jwt()
    request = build_conn(:put, "/is/users/mike") |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\": \"ok\"}"
  end

  test "forward_request should handle DELETE method", %{second_service: second_service} do
    Bypass.expect second_service, fn conn ->
      assert "/ps/tasks/95258830-28c6-11e7-a7ed-a1b56e729040" == conn.request_path
      assert "DELETE" == conn.method
      Plug.Conn.resp(conn, 204, ~s<>)
    end

    jwt = generate_jwt()
    request = build_conn(:delete, "/ps/tasks/95258830-28c6-11e7-a7ed-a1b56e729040") 
      |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    assert conn.status == 204
    assert conn.resp_body =~ ""
  end

  test "forward_request should handle IDs with . symbol", %{first_service: first_service} do
    Bypass.expect first_service, fn conn ->
      assert "/is/users/first.user" == conn.request_path
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"response":"[]"}>)
    end

    jwt = generate_jwt()
    request = build_conn(:get, "/is/users/first.user") 
      |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end

  test "forward_request should handle UUIDs", %{second_service: second_service} do
    Bypass.expect second_service, fn conn ->
      assert "/ps/tasks/95258830-28c6-11e7-a7ed-a1b56e729040" == conn.request_path
      assert "GET" == conn.method
      Plug.Conn.resp(conn, 200, ~s<{"response":"[]"}>)
    end

    jwt = generate_jwt()
    request = build_conn(:get, "/ps/tasks/95258830-28c6-11e7-a7ed-a1b56e729040") 
      |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end

  test "forward_request should handle nested query params", %{third_service: third_service} do
    Bypass.expect third_service, fn conn ->
      assert "/ts/transactions" == conn.request_path
      assert "GET" == conn.method
      assert "page[limit]=10&page[offset]=0" == conn.query_string
      Plug.Conn.resp(conn, 200, ~s<{"response":"[]"}>)
    end

    jwt = generate_jwt()
    request = build_conn(:get, "/ts/transactions", %{"page" => %{"offset" => 0, "limit" => 10}}) 
      |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end
  
  test "forward_request should handle POST request with file body", %{first_service: first_service} do
    Bypass.expect first_service, fn conn ->
      assert "/is/auth" == conn.request_path
      assert "POST" == conn.method
      {:ok, body, _conn} = Plug.Conn.read_body(conn)
      assert body |> String.contains?("name=\"random_data\"\r\n\r\n123\r\n")
      Plug.Conn.resp(conn, 201, ~s<{"response": "file uploaded successfully"}>)
    end

    jwt = generate_jwt()
    upload = %Plug.Upload{
      path: "test/lib/gateway/api_proxy/upload_example.txt",
      filename: "upload_example.txt",
      content_type: "plain/text",
    }
    request = build_conn(
      :post,
      "/is/auth",
      %{:qqfile => upload, :random_data => "123"}) |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    assert conn.status == 201
    assert conn.resp_body =~ "{\"response\": \"file uploaded successfully\"}"
  end

  test "send_response should chunk response if transfer-encoding is set", %{third_service: third_service} do
    Bypass.expect third_service, fn conn ->
      assert "/ts/transactions" == conn.request_path
      assert "GET" == conn.method
      {:ok, conn} =
        conn
        |> put_resp_header("transfer-encoding", "chunked")
        |> Plug.Conn.send_chunked(200)
        |> Plug.Conn.chunk(~s<{"response":"[]"}>)
      conn
    end

    jwt = generate_jwt()
    request = build_conn(:get, "/ts/transactions") 
      |> put_req_header("authorization", jwt)
    conn = call(Gateway.Router, request)
    
    assert conn.status == 200
    assert conn.state == :chunked
  end

  defp call(mod, conn) do
    mod.call(conn, [])
  end
end
