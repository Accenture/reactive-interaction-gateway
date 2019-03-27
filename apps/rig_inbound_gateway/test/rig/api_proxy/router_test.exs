defmodule RigInboundGateway.ApiProxy.RouterTest do
  @moduledoc false
  # cause FakeServer opens a port:
  use ExUnit.Case, async: false
  use RigInboundGatewayWeb.ConnCase

  import FakeServer
  alias FakeServer.Response

  alias RigInboundGatewayWeb.Router

  @env [port: 7070]

  test "not defined endpoint should return 404" do
    conn = call(Router, build_conn(:get, "/random/route"))
    assert conn.status == 404
  end

  test "protected endpoint with invalid JWT should return 401" do
    conn = call(Router, build_conn(:get, "/myapi/books"))
    assert conn.status == 401
  end

  test_with_server "protected endpoint with valid JWT should return response", @env do
    route("/myapi/books", Response.ok!(~s<{"status":"ok"}>))

    request = construct_request_with_jwt(:get, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test_with_server "authentication free endpoint should successfully return response", @env do
    route("/myapi/free", Response.ok!(~s<{"status":"ok"}>))

    conn = call(Router, build_conn(:get, "/myapi/free"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test_with_server "endpoint with POST method should successfully return response", @env do
    route("/myapi/books", fn %{method: "POST"} ->
      Response.ok!(~s<{"status":"ok"}>)
    end)

    request = construct_request_with_jwt(:post, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test_with_server "endpoint with PUT method should successfully return response", @env do
    route("/myapi/books", fn %{method: "PUT"} ->
      Response.ok!(~s<{"status":"ok"}>)
    end)

    request = construct_request_with_jwt(:put, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test_with_server "endpoint with PATCH method should successfully return response", @env do
    route("/myapi/books", fn %{method: "PATCH"} ->
      Response.ok!(~s<{"status":"ok"}>)
    end)

    request = construct_request_with_jwt(:patch, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test_with_server "endpoint with DELETE method should successfully return response", @env do
    route("/myapi/books", fn %{method: "DELETE"} ->
      Response.ok!(~s<{"status":"ok"}>)
    end)

    request = construct_request_with_jwt(:delete, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test_with_server "endpoint with HEAD method should successfully return response", @env do
    route("/myapi/books", fn %{method: "HEAD"} ->
      Response.ok!(~s<{"status":"ok"}>)
    end)

    request = construct_request_with_jwt(:head, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    # HEAD request responds only with headers
    assert conn.resp_body =~ ""
  end

  test_with_server "endpoint with OPTIONS method should successfully return response", @env do
    route("/myapi/books", fn %{method: "OPTIONS"} ->
      Response.ok!(~s<{"status": "ok"}>)
    end)

    request = construct_request_with_jwt(:options, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\": \"ok\"}"
  end

  test "endpoint with unsupported method should return 405" do
    request = construct_request_with_jwt(:badmethod, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 405
  end

  test_with_server "forward_request should handle IDs with . symbol", @env do
    route("/myapi/detail/first.user", Response.ok!(~s<{"response":"[]"}>))

    request = construct_request_with_jwt(:get, "/myapi/detail/first.user")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end

  test_with_server "forward_request should handle UUIDs", @env do
    route(
      "/myapi/detail/95258830-28c6-11e7-a7ed-a1b56e729040",
      Response.ok!(~s<{"response":"[]"}>)
    )

    request =
      construct_request_with_jwt(:get, "/myapi/detail/95258830-28c6-11e7-a7ed-a1b56e729040")

    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end

  test_with_server "forward_request should handle nested query params", @env do
    route("/myapi/books", fn %{query: query} ->
      assert %{"page[limit]" => "10", "page[offset]" => "0"} = query
      Response.ok!(~s<{"response":"[]"}>)
    end)

    request =
      construct_request_with_jwt(:get, "/myapi/books", %{
        "page" => %{"offset" => 0, "limit" => 10}
      })

    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"response\":\"[]\"}"
  end

  test_with_server "forward_request should handle POST request with file body", @env do
    route("/myapi/books", fn %{method: "POST", body: body} ->
      assert String.contains?(body, "name=\"random_data\"\r\n\r\n123\r\n")
      assert String.contains?(body, "filename=\"upload_example.txt\"\r\n\r\nHello\r\n")
      Response.created!(~s<{"response": "file uploaded successfully"}>)
    end)

    upload = %Plug.Upload{
      path: __DIR__ <> "/upload_example.txt",
      filename: "upload_example.txt",
      content_type: "plain/text"
    }

    request =
      construct_request_with_jwt(:post, "/myapi/books", %{
        "qqfile" => upload,
        "random_data" => "123"
      })

    conn = call(Router, request)
    assert conn.status == 201
    assert conn.resp_body =~ "{\"response\": \"file uploaded successfully\"}"
  end

  test_with_server "Any request should include forward headers", @env do
    route("/myapi/direct", Response.ok!(~s<{"status":"ok"}>))

    conn = call(Router, build_conn(:get, "/myapi/direct"))

    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
    assert [forwarded_header] = get_req_header(conn, "forwarded")
    assert forwarded_header =~ ~r/for=[^;]+;by=.*/
  end

  test_with_server "should skip auth if no auth method is set", @env do
    route("/myapi/direct", Response.ok!(~s<{"status":"ok"}>))

    conn = call(Router, build_conn(:get, "/myapi/direct"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test_with_server "transform_req_headers should update existing and add new request headers, if requested",
                   @env do
    route("/myapi/transform-headers", fn %{method: "POST"} ->
      Response.ok!(~s<{"status":"ok"}>)
    end)

    request = build_conn(:post, "/myapi/transform-headers") |> put_req_header("host", "original")
    conn = call(Router, request)

    assert get_req_header(conn, "host") == ["different"]
    assert get_req_header(conn, "john") == ["doe"]
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  test_with_server "transform_req_headers shouldn\'t update existing and add new request headers, if not requested",
                   @env do
    route("/myapi/no-transform-headers", fn %{method: "POST"} ->
      Response.ok!(~s<{"status":"ok"}>)
    end)

    request =
      build_conn(:post, "/myapi/no-transform-headers") |> put_req_header("host", "original")

    conn = call(Router, request)

    assert get_req_header(conn, "host") == ["original"]
    assert get_req_header(conn, "john") == []
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"
  end

  @tag :smoke
  test "GET request should be correctly proxied to external service" do
    conn = call(Router, build_conn(:get, "/api"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"msg\":\"GET\"}"
  end

  @tag :smoke
  test "POST request should be correctly proxied to external service" do
    conn = call(Router, build_conn(:post, "/api"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"msg\":\"POST\"}"
  end

  @tag :smoke
  test "PUT request should be correctly proxied to external service" do
    conn = call(Router, build_conn(:put, "/api"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"msg\":\"PUT\"}"
  end

  @tag :smoke
  test "PATCH request should be correctly proxied to external service" do
    conn = call(Router, build_conn(:patch, "/api"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"msg\":\"PATCH\"}"
  end

  @tag :smoke
  test "DELETE request should be correctly proxied to external service" do
    conn = call(Router, build_conn(:delete, "/api"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"msg\":\"DELETE\"}"
  end

  @tag :smoke
  test "HEAD request should be correctly proxied to external service" do
    conn = call(Router, build_conn(:head, "/api"))
    assert conn.status == 200
    assert conn.resp_body =~ ""
  end

  @tag :smoke
  test "OPTIONS request should be correctly proxied to external service" do
    conn = call(Router, build_conn(:options, "/api"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"msg\":\"OPTIONS\"}"
  end

  @tag :smoke
  test "POST request with file body should be correctly proxied to external service" do
    upload = %Plug.Upload{
      path: __DIR__ <> "/upload_example.txt",
      filename: "upload_example.txt",
      content_type: "plain/text"
    }

    conn = call(Router, build_conn(:post, "/api", %{"qqfile" => upload}))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"msg\":\"POST FILE\"}"
  end

  @tag :smoke
  test "GET request with queries should be correctly proxied to external service" do
    conn = call(Router, build_conn(:get, "/api", %{"foo" => %{"bar" => "baz"}}))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"msg\":\"GET QUERY\"}"
  end

  defp construct_request_with_jwt(method, url, query \\ %{}) do
    jwt = generate_jwt()

    build_conn(method, url, query)
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  defp call(mod, conn) do
    mod.call(conn, [])
  end
end
