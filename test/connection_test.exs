defmodule RigInboundGateway.ConnectionTest do
  use ExUnit.Case, async: true

  require Logger

  alias HTTPoison

  @dispatch Confex.fetch_env!(:rig, RigInboundGatewayWeb.Endpoint)[:https][:dispatch]
  @port 47_210

  setup_all do
    dispatch = :cowboy_router.compile(@dispatch)
    server_name = __MODULE__
    {:ok, _pid} = :cowboy.start_clear(server_name, [port: @port], %{env: %{dispatch: dispatch}})

    on_exit(fn ->
      :cowboy.stop_listener(server_name)
    end)

    :ok
  end

  defp try_sse(params \\ []) do
    SseClient.try_connect_then_disconnect(params)
  end

  defp try_ws(params \\ []) do
    WsClient.try_connect_then_disconnect(params)
  end

  defp try_longpolling(params) do
    url = "http://localhost:#{@port}/_rig/v1/connection/longpolling?#{URI.encode_query(params)}"
    %HTTPoison.Response{status_code: status_code} = HTTPoison.get!(url)
    status_code
  end

  describe "Parameter handling:" do
    test ~S(Neither "jwt" nor "subscriptions" are required to connect.") do
      assert {:ok, _} = try_sse()
      assert {:ok, _} = try_ws()
      assert 200 == try_longpolling(jwt: nil, subscriptions: nil)
    end

    test "Passing an invalid JWT closes the connection with a request error." do
      assert {:error, %{code: 400}} = try_sse(jwt: "foobar")
      assert {:error, _} = try_ws(jwt: "foobar")
      assert 400 == try_longpolling(jwt: "foobar", subscriptions: nil)
    end

    test "Passing an invalid subscriptions value closes the connection with a request error." do
      assert {:error, %{code: 400}} = try_sse(subscriptions: "can't { be [ parsed.")
      assert {:error, _} = try_ws(subscriptions: "can't { be [ parsed.")
      assert 400 == try_longpolling(jwt: nil, subscriptions: "can't { be [ parsed.")
    end
  end
end
