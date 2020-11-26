defmodule RigInboundGatewayWeb.ConnectionInitTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias RigInboundGateway.ProxyConfig
  alias RigInboundGatewayWeb.ConnectionInit

  @conn_type "SSE"
  @request %{
    auth_info: nil,
    query_params: "",
    content_type: "application/json; charset=utf-8",
    body: nil
  }
  @default_interval 10_000

  defp noop(_), do: nil

  defp set_up_connection do
    ConnectionInit.set_up(
      @conn_type,
      @request,
      &noop/1,
      &noop/1,
      @default_interval,
      @default_interval
    )
  end

  test "The max connection limit is respected" do
    orig_config = ProxyConfig.set("MAX_CONNECTIONS_PER_MINUTE", "5")
    Enum.each(0..4, fn _ -> set_up_connection() end)

    assert capture_log(fn ->
             set_up_connection()
           end) =~
             "Reached maximum number of connections=5 per minute"

    ProxyConfig.restore("MAX_CONNECTIONS_PER_MINUTE", orig_config)
  end
end
