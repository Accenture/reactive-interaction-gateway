defmodule RigInboundGatewayWeb.Presence.ChannelTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  use RigInboundGatewayWeb.ChannelCase

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
end
