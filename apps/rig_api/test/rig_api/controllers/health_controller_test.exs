defmodule RigApi.HealthControllerTest do
  @moduledoc false
  require Logger
  use ExUnit.Case, async: true
  use RigApi.ConnCase

  describe "GET /health" do
    test "should return OK as text response" do
      conn = build_conn() |> get("/health")
      content_type = get_resp_header(conn, "content-type")
      assert conn.resp_body == "OK"
      assert content_type == ["text/plain; charset=utf-8"]
    end
  end
end
