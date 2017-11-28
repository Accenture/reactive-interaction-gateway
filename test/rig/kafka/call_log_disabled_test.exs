defmodule Rig.Kafka.CallLogDisabledTest do
  @moduledoc false
  use Rig.Config, [:jwt_secret_key]
  use ExUnit.Case, async: false  # Application env is modified during tests
  import Phoenix.ConnTest, only: [build_conn: 0]
  import Plug.Conn, only: [put_req_header: 3]
  import Rig.Kafka, only: [log_proxy_api_call: 3]

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

  defmacro set_log_topic(topic, do: do_block) do
    quote do
      kafka_conf = Application.get_env(:rig, Rig.Kafka, [])
      Application.put_env(:rig, Rig.Kafka, Keyword.merge(kafka_conf, [log_topic: unquote(topic)]))
      unquote(do_block)
      Application.put_env(:rig, Rig.Kafka, kafka_conf)
    end
  end

  test "logging is disabled if the Kafka topic is empty", %{route: route} do
    set_log_topic "" do
      conn = make_conn(%{"username" => "the.user", "jti" => "THE_TOKEN_ID"})
      produce_sync = fn (_, _, _, _, _) -> raise "should not be called" end
      assert log_proxy_api_call(route, conn, produce_sync) == :ok
    end
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
