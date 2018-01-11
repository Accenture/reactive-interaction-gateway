defmodule RigApiWeb.MessageControllerTest do
  @moduledoc false
  use RigApi.ConnCase
  use RigApi.ChannelCase

  setup do
    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn}
  end

  describe "posting a message" do
    test "should return :accepted if successful", %{conn: conn} do
      # Let's verify that the message actually gets delivered:
      @endpoint.subscribe(_channel = "user:testuser")

      body = ~s({"user":"testuser","foo":"bar"})
      conn = post conn, "/v1/messages", body
      assert conn.status == 202

      expected_event = "message"
      expected_payload = %{"user" => "testuser", "foo" => "bar"}
      assert_broadcast ^expected_event, ^expected_payload
    end

    test "should return :bad_request if missing user field", %{conn: conn} do
      body = ~s({"foo":"bar"})
      conn = post conn, "/v1/messages", body
      assert conn.status == 400
    end
  end
end
