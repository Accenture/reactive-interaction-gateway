defmodule RigApi.HealthControllerTest do
  @moduledoc false
  require Logger
  use ExUnit.Case, async: true
  use RigApi.ConnCase

  describe "GET /health" do
    test "should return OK as text response" do
      conn = build_conn() |> get("/health")
      assert conn.resp_body == "OK"
      assert "text/plain" == resp_content_type(conn)
    end
  end

  # The response content-type with parameters stripped (e.g. "text/plain").
  defp resp_content_type(conn) do
    [{:ok, type, subtype, _params}] =
      conn
      |> get_resp_header("content-type")
      |> Enum.map(&Plug.Conn.Utils.content_type/1)

    "#{type}/#{subtype}"
  end
end
