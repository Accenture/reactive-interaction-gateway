defmodule RigInboundGateway.ApiProxy.ProxyMetricsTest do
  @moduledoc false
  # cause FakeServer opens a port:
  use ExUnit.Case, async: false
  use RigInboundGatewayWeb.ConnCase

  import FakeServer
  alias FakeServer.Response

  alias RIG.JWT
  alias RigMetrics.ProxyMetrics

  alias RigInboundGatewayWeb.Router

  @env [port: 7070]

  test_with_server "Metric should track undefined routes", @env do
    metric_status_before =
      ProxyMetrics.get_current_value(
        "GET",
        "/endpoint/undefined",
        "N/A",
        "N/A",
        "not_found"
      )

    request = construct_request_with_jwt(:get, "/endpoint/undefined")
    conn = call(Router, request)
    assert conn.status == 404

    metric_status_after =
      ProxyMetrics.get_current_value(
        "GET",
        "/endpoint/undefined",
        "N/A",
        "N/A",
        "not_found"
      )

    if metric_status_before === :undefined do
      assert metric_status_after === 1
    else
      assert metric_status_after === metric_status_before + 1
    end
  end

  # ---

  test_with_server "Standard HTTP call should increase metrics counter", @env do
    route("/myapi/free", Response.ok!(~s<{"status":"ok"}>))

    metric_status_before =
      ProxyMetrics.get_current_value("GET", "/myapi/free", "http", "http", "ok")

    conn = call(Router, build_conn(:get, "/myapi/free"))
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"

    metric_status_after =
      ProxyMetrics.get_current_value("GET", "/myapi/free", "http", "http", "ok")

    if metric_status_before === :undefined do
      assert metric_status_after === 1
    else
      assert metric_status_after === metric_status_before + 1
    end
  end

  # ---

  test_with_server "Metric should track methods correctly", @env do
    route("/myapi/books", fn %{method: "POST"} ->
      Response.ok!(~s<{"status":"ok"}>)
    end)

    metric_status_before =
      ProxyMetrics.get_current_value("POST", "/myapi/books", "http", "http", "ok")

    request = construct_request_with_jwt(:post, "/myapi/books")
    conn = call(Router, request)
    assert conn.status == 200
    assert conn.resp_body =~ "{\"status\":\"ok\"}"

    metric_status_after =
      ProxyMetrics.get_current_value("POST", "/myapi/books", "http", "http", "ok")

    if metric_status_before === :undefined do
      assert metric_status_after === 1
    else
      assert metric_status_after === metric_status_before + 1
    end
  end

  # ---

  defp construct_request_with_jwt(method, url, query \\ %{}) do
    jwt = JWT.encode(%{})

    build_conn(method, url, query)
    |> put_req_header("authorization", "Bearer #{jwt}")
  end

  defp call(mod, conn) do
    mod.call(conn, [])
  end
end
