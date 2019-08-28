defmodule RigInboundGateway.ConnectionTest do
  use ExUnit.Case, async: true

  require Logger

  alias HTTPoison
  alias Socket.Web, as: WebSocket

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

  defp flush_mailbox do
    receive do
      _ -> flush_mailbox()
    after
      10 -> :ok
    end
  end

  defp try_sse(params) do
    url = "http://localhost:#{@port}/_rig/v1/connection/sse?#{URI.encode_query(params)}"

    %HTTPoison.AsyncResponse{id: client} =
      HTTPoison.get!(url, %{},
        stream_to: self(),
        recv_timeout: 20_000
      )

    status_code =
      receive do
        %HTTPoison.AsyncStatus{code: code} -> code
      after
        500 -> raise "No response"
      end

    flush_mailbox()
    {:ok, ^client} = :hackney.stop_async(client)
    flush_mailbox()
    status_code
  end

  defp try_longpolling(params) do
    url = "http://localhost:#{@port}/_rig/v1/connection/longpolling?#{URI.encode_query(params)}"

    %HTTPoison.Response{status_code: res_status} = HTTPoison.get!(url)

    res_status
  end

  defp try_ws(params) do
    {:ok, client} =
      WebSocket.connect("localhost", @port, %{
        path: "/_rig/v1/connection/ws?#{URI.encode_query(params)}",
        protocol: ["ws"]
      })

    result =
      case WebSocket.recv!(client) do
        {:text, payload} -> {:ok, payload}
        {:close, :normal, reason} -> {:error, reason}
      end

    :ok = WebSocket.close(client)
    result
  end

  describe "Parameter handling:" do
    test ~S(Neither "jwt" nor "subscriptions" are required to connect.") do
      assert 200 = try_sse(jwt: nil, subscriptions: nil)
      assert {:ok, _} = try_ws(jwt: nil, subscriptions: nil)
      assert 200 == try_longpolling(jwt: nil, subscriptions: nil)
    end

    test "Passing an invalid JWT closes the connection with a request error." do
      assert 400 = try_sse(jwt: "foobar", subscriptions: nil)
      assert {:error, _} = try_ws(jwt: "foobar", subscriptions: nil)
      assert 400 == try_longpolling(jwt: "foobar", subscriptions: nil)
    end

    test "Passing an invalid subscriptions value closes the connection with a request error." do
      assert 400 = try_sse(jwt: nil, subscriptions: "can't { be [ parsed.")
      assert {:error, _} = try_ws(jwt: nil, subscriptions: "can't { be [ parsed.")
      assert 400 == try_longpolling(jwt: nil, subscriptions: "can't { be [ parsed.")
    end
  end
end
