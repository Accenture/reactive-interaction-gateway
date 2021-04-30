defmodule RigMetricsTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use RigApi.ConnCase

  require Logger

  setup do
    # enable metrics to be able to test them
    RigMetrics.EventsMetrics.setup()
    RigMetrics.ProxyMetrics.setup()
    RigMetrics.MetricsPlugExporter.setup()
    :ok
  end

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
