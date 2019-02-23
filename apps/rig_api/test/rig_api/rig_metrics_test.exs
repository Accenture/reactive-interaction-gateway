defmodule RigMetricsTest do
  @moduledoc false
  require Logger
  use ExUnit.Case, async: true
  use RigApi.ConnCase

  describe "GET /metrics" do
    test "should return 'something'" do
      conn = build_conn() |> get("/metrics")
      assert "text/plain" == resp_content_type(conn)
      assert conn.status == 200
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
