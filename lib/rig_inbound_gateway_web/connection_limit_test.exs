defmodule RigInboundGatewayWeb.ConnectionLimitTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias RigInboundGatewayWeb.ConnectionLimit

  test "The limit is respected" do
    ets_table = __MODULE__.BasicTest
    opts = [ets_table: ets_table, limit_per_minute: 2]
    {:ok, pid} = ConnectionLimit.start_link(opts)

    assert {:ok, 1} = ConnectionLimit.add_connection(opts)
    assert {:ok, 2} = ConnectionLimit.add_connection(opts)
    assert {:error, :connection_limit_exceeded} = ConnectionLimit.add_connection(opts)

    GenServer.stop(pid)
  end

  test "Doesn't crash a connection if the ETS table is not there (yet)" do
    ets_table = __MODULE__.DoesNotExist
    opts = [ets_table: ets_table]
    assert {:ok, _} = ConnectionLimit.add_connection(opts)
  end
end
