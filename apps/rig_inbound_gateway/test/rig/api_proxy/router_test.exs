defmodule RigInboundGateway.ApiProxy.RouterTest do
  @moduledoc false
  use ExUnit.Case, async: false  # cause Bypass opens ports
  use RigInboundGatewayWeb.ConnCase

  import Joken

  alias RigInboundGatewayWeb.Router
  alias RigInboundGateway.RateLimit
  alias RigInboundGateway.RateLimit.Common

  setup do
    # Other tests might have filled the table, so we reset it:
    conf = RateLimit.config()

    conf.table_name
    |> Common.ensure_table
    |> :ets.delete_all_objects

    boot_service(Bypass.open(port: 7070))
  end

  defp boot_service(first_service) do
    case first_service do
      {:error, :eaddrinuse} -> boot_service(Bypass.open(port: 7070))
      # Retry for new instance if previous didn't manage to exit
      _ -> {:ok, first_service: first_service}
    end
  end

  test "not defined endpoint should return 404" do
    conn = call(Router, build_conn(:get, "/random/route"))
    assert conn.status == 404
    assert conn.resp_body =~ "{\"message\":\"Route is not available\"}"
  end

  test "protected endpoint with invalid JWT should return 401" do
    conn = call(Router, build_conn(:get, "/myapi/books"))
    assert conn.status == 401
    assert conn.resp_body =~ "{\"message\":\"Missing or invalid token\"}"
  end

  test "protected endpoint with valid JWT should return response",
  %{first_service: first_service} do
    Bypass.expect first_service, "GET", "/myapi/books", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status":"ok"}>)
    end

    request = construct_request_with_jwt(:get, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test "authentication free endpoint should successfully return response",
  %{first_service: first_service} do
    Bypass.expect first_service, "GET", "/myapi/free", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status":"ok"}>)
    end

    conn = call(Router, build_conn(:get, "/myapi/free"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test "endpoint with POST method should successfully return response",
  %{first_service: first_service} do
    Bypass.expect first_service, "POST", "/myapi/books", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status":"ok"}>)
    end

    request = construct_request_with_jwt(:post, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test "endpoint with PUT method should successfully return response",
  %{first_service: first_service} do
    Bypass.expect first_service, "PUT", "/myapi/books", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status":"ok"}>)
    end

    request = construct_request_with_jwt(:put, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test "endpoint with PATCH method should successfully return response",
  %{first_service: first_service} do
    Bypass.expect first_service, "PATCH", "/myapi/books", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status":"ok"}>)
    end

    request = construct_request_with_jwt(:patch, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test "endpoint with DELETE method should successfully return response",
  %{first_service: first_service} do
    Bypass.expect first_service, "DELETE", "/myapi/books", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status":"ok"}>)
    end

    request = construct_request_with_jwt(:delete, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test "endpoint with HEAD method should successfully return response",
  %{first_service: first_service} do
    Bypass.expect first_service, "HEAD", "/myapi/books", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status":"ok"}>)
    end

    request = construct_request_with_jwt(:head, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    # HEAD request responds only with headers
    assert conn.resp_body =~ ""
  end

  test "endpoint with OPTIONS method should successfully return response",
  %{first_service: first_service} do
    Bypass.expect first_service, "OPTIONS", "/myapi/books", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status": "ok"}>)
    end

    request = construct_request_with_jwt(:options, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\": \"ok\"}"
  end

  test "endpoint with unsupported method should return 405" do
    request = construct_request_with_jwt(:badmethod, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 405
    assert conn.resp_body =~ "{\"message\":\"Method is not supported\"}"
  end

  test "forward_request should handle IDs with . symbol", %{first_service: first_service} do
    Bypass.expect first_service, "GET", "/myapi/detail/first.user", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"response":"[]"}>)
    end

    request = construct_request_with_jwt(:get, "/myapi/detail/first.user")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end

  test "forward_request should handle UUIDs", %{first_service: first_service} do
    Bypass.expect first_service, "GET", "/myapi/detail/95258830-28c6-11e7-a7ed-a1b56e729040", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"response":"[]"}>)
    end

    request = construct_request_with_jwt(:get, "/myapi/detail/95258830-28c6-11e7-a7ed-a1b56e729040")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end

  test "forward_request should handle nested query params", %{first_service: first_service} do
    Bypass.expect first_service, "GET", "/myapi/books", fn conn ->
      assert "page[limit]=10&page[offset]=0" == conn.query_string
      Plug.Conn.resp(conn, 200, ~s<{"response":"[]"}>)
    end

    request = construct_request_with_jwt(:get, "/myapi/books", %{"page" => %{"offset" => 0, "limit" => 10}})
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end

  test "forward_request should handle POST request with file body", %{first_service: first_service} do
    Bypass.expect first_service, "POST", "/myapi/books", fn conn ->
      {:ok, body, _conn} = Plug.Conn.read_body(conn)
      assert body |> String.contains?("name=\"random_data\"\r\n\r\n123\r\n")
      assert body |> String.contains?("filename=\"upload_example.txt\"\r\n\r\nHello\r\n")
      Plug.Conn.resp(conn, 201, ~s<{"response": "file uploaded successfully"}>)
    end

    upload = %Plug.Upload{
      path: __DIR__ <> "/upload_example.txt",
      filename: "upload_example.txt",
      content_type: "plain/text",
    }

    request = construct_request_with_jwt(:post, "/myapi/books", %{"qqfile" => upload, "random_data" => "123"})
    conn = call(Router, request)
    assert conn.status == 201
    assert conn.resp_body =~ "{\"response\": \"file uploaded successfully\"}"
  end

  test "send_response should chunk response if transfer-encoding is set to chunked",
  %{first_service: first_service} do
    Bypass.expect first_service, "GET", "/myapi/books", fn conn ->
      {:ok, conn} =
        conn
        |> put_resp_header("transfer-encoding", "chunked")
        |> Plug.Conn.send_chunked(200)
        |> Plug.Conn.chunk(~s<{"response":"[]"}>)
      conn
    end

    request = construct_request_with_jwt(:get, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.state == :chunked
  end

  test "should skip auth if no auth method is set",
  %{first_service: first_service} do
    Bypass.expect first_service, "GET", "/myapi/direct", fn conn ->
      Plug.Conn.resp(conn, 200, ~s<{"status":"ok"}>)
    end

    conn = call(Router, build_conn(:get, "/myapi/direct"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  defp construct_request_with_jwt(method, url, query \\ %{}) do
    jwt = generate_jwt()
    build_conn(method, url, query)
    |> put_req_header("authorization", jwt)
  end

  defp call(mod, conn) do
    mod.call(conn, [])
  end
end
