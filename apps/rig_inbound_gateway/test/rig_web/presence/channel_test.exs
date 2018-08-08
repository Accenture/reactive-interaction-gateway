defmodule RigInboundGatewayWeb.Presence.ChannelTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  use RigInboundGatewayWeb.ChannelCase
  use RigInboundGatewayWeb.ConnCase

  setup do
    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")

    {:ok, conn: conn}
  end

  test "a user connecting to her own topic works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      [@customer_role],
      "user:testuser"
    )
    leave sock
  end

  test "a user connecting to someone else's topic with not authorized role fails" do
    fun = fn ->
      assert {:error, _message} = subscribe_and_join_user(
        "foo-user",
        [@customer_role],
        "user:bar-user"
      )
    end
    assert capture_log(fun) =~ "unauthorized"
  end

  test "a user connecting to someone else's topic with authorized role works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "foo-user",
      [@support_role],
      "user:testuser"
    )
    leave sock
  end

  test "a user connecting to role specific topic with authorized role works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "foo-user",
      [@support_role],
      "role:customer"
    )
    leave sock
  end

  test "a user connecting to role specific topic without authorized role fails" do
    fun = fn ->
      assert {:error, _message} = subscribe_and_join_user(
        "foo-user",
        [@customer_role],
        "role:customer"
      )
    end
    assert capture_log(fun) =~ "unauthorized"
  end

  @tag :smoke
  test "subscribed user should receive message", %{conn: conn} do
    true = RigOutboundGateway.Kafka.ready?("rig", 0, 10_000)
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      [@customer_role],
      "user:testuser"
    )

    body = ~s({"user":"testuser","foo":"bar"})
    produce_kafka_message(conn, body)

    expected_event = "message"
    expected_payload = %{"user" => "testuser", "foo" => "bar"}
    assert_broadcast ^expected_event, ^expected_payload, 3000

    leave sock
  end

  @tag :smoke
  test "not subscribed user shouldn't receive message", %{conn: conn} do
    true = RigOutboundGateway.Kafka.ready?("rig", 0, 10_000)
    body = ~s({"user":"testuser","foo":"bar"})
    produce_kafka_message(conn, body)

    expected_event = "message"
    expected_payload = %{"user" => "testuser", "foo" => "bar"}
    refute_broadcast ^expected_event, ^expected_payload, 2000
  end

  defp produce_kafka_message(conn, body) do
    conn = post conn, "/kafka/produce", body
    assert conn.status == 200
  end
end
