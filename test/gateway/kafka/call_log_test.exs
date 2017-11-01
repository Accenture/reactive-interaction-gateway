defmodule Gateway.Kafka.CallLogTest do
  @moduledoc false
  use Gateway.Config, [:jwt_secret_key]
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Conn, only: [put_req_header: 3]
  import Gateway.Kafka, only: [log_proxy_api_call: 3]

  setup do
    route = %{
      "host" => "theHost",
      "port" => 1234,
      "path" => "/some/path",
      "method" => "POST",
      "auth" => true,
    }
    %{route: route}
  end

  test "it works", %{route: route} do
    username = "the.user"
    conn = make_conn(%{
      "username" => username,
      "jti" => "THE_TOKEN_ID",
    })
    produce_sync = fn (_, _, _, ^username, _) -> :ok end
    assert log_proxy_api_call(route, conn, produce_sync) == :ok
  end

  test "it fails if the claims lack the username", %{route: route} do
    conn = make_conn(%{
      "jti" => "THE_TOKEN_ID",
    })
    produce_sync = fn (_, _, _, _, _) -> assert false end
    fun = fn ->
      {:error, %KeyError{key: "username"}} = log_proxy_api_call(route, conn, produce_sync)
    end
    assert capture_log(fun) =~ "username is required"
  end

  test "it works but warns if the claims lack the jti", %{route: route} do
    username = "the.user"
    conn = make_conn(%{
      "username" => username,
    })
    produce_sync = fn (_, _, _, ^username, _) -> :ok end
    fun = fn ->
      assert log_proxy_api_call(route, conn, produce_sync) == :ok
    end
    assert capture_log(fun) =~ "jti not found in claims"
  end

  defp make_conn(claims) do
    build_conn()
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", claims |> make_jwt)
  end

  defp make_jwt(claims) do
    import Joken
    conf = config()
    claims
    |> token
    |> with_exp
    |> with_signer(conf.jwt_secret_key |> hs256)
    |> sign
    |> get_compact
  end
end
