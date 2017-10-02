defmodule Gateway.RateLimit.ProxyIntegrationTest do
  @moduledoc false
  use ExUnit.Case, async: false  # we rely on clearing the ETS table
  import ExUnit.CaptureLog
  alias Gateway.RateLimit.Common

  test "integration with proxy" do
    Bypass.open(port: 7070)
    |> Bypass.expect(&(Plug.Conn.resp(&1, 200, "")))

    call_endpoint = fn ->
      conn =
        Phoenix.ConnTest.build_conn(:get, "/myapi/free")
        |> GatewayWeb.Router.call([])
      conn.status
    end

    %{burst_size: burst_size, table_name: table} = Common.settings()
    # Other tests might have filled the table, so we reset it:
    table
    |> Common.ensure_table
    |> :ets.delete_all_objects
    for _ <- 1..burst_size do
      assert call_endpoint.() == 200
    end

    fun = fn -> assert call_endpoint.() == 429 end
    assert capture_log(fun) =~ "Too many requests"

    :ets.delete(table)
  end
end
