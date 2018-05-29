defmodule RigApiWeb.MessageControllerTest do
  @moduledoc false
  use RigApi.ConnCase
  use RigApi.ChannelCase

  defp new_conn(content_type) do
    build_conn()
    |> put_req_header("content-type", content_type)
  end

  describe "The messages endpoint, when posting a message," do
    test "returns :accepted if successful" do
      # Let's verify that the message actually gets delivered:
      @endpoint.subscribe(_channel = "user:testuser")

      conn =
        new_conn("application/json")
        |> post("/v1/messages", ~s({"user":"testuser","foo":"bar"}))

      assert conn.status == 202
      expected_event = "message"
      expected_payload = %{"user" => "testuser", "foo" => "bar"}
      assert_broadcast(^expected_event, ^expected_payload)
    end

    test "returns :bad_request if passed a string instead of a map" do
      conn = new_conn("application/json")

      # exception would be translated to conn.status == 400
      assert_raise Plug.Parsers.ParseError, ~r/malformed request/, fn ->
        post(conn, "/v1/messages", ~s("{\"foo\":\"bar\"}"))
      end
    end

    test "returns :bad_request if missing user field" do
      conn =
        new_conn("application/json")
        |> post("/v1/messages", ~s({"foo":"bar"}))

      assert conn.status == 400
    end

    test "handles application/json with charset parameter set" do
      conn =
        new_conn("application/json;charset=utf-8")
        |> post("/v1/messages", ~s({"user":"testuser","foo":"bar"}))

      assert conn.status == 202
    end

    test "handles application/x-www-form-urlencoded with charset parameter set" do
      conn =
        new_conn("application/x-www-form-urlencoded;charset=utf-8")
        |> post("/v1/messages", "user=testuser&foo=bar")

      assert conn.status == 202
    end

    test "declines unknown content-types (e.g., text/plain)" do
      conn = new_conn("text/plain")

      # exception would be translated to conn.status == 415
      assert_raise Plug.Parsers.UnsupportedMediaTypeError,
                   "unsupported media type text/plain",
                   fn ->
                     post(conn, "/v1/messages", "user=testuser&foo=bar")
                   end
    end
  end
end
