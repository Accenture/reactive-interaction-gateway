defmodule RigApi.HealthControllerTest do
    @moduledoc false
    require Logger
    use ExUnit.Case, async: true
    use RigApi.ConnCase
  
    describe "GET /health" do
      test "should return OK as text response" do
        conn = build_conn() |> get("/health")
        assert conn.resp_body =~ "OK"
      end
    end
  end