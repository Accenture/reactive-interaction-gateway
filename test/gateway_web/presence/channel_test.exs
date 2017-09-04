defmodule GatewayWeb.Presence.ChannelTest do
  use ExUnit.Case, async: true
  use GatewayWeb.ChannelCase
  alias GatewayWeb.Presence
  alias GatewayWeb.Presence.Channel

  test "a user connecting to her own topic works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      [@customer_role],
      "user:testuser"
    )
    leave sock
  end

  test "a user connecting to someone else's topic with not authorized role fails" do
    assert {:error, _message} = subscribe_and_join_user(
      "foo-user",
      [@customer_role],
      "user:bar-user"
    )
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
    assert {:error, _message} = subscribe_and_join_user(
      "foo-user",
      [@customer_role],
      "role:customer"
    )
  end

  test "a user joining/leaving channel should be tracked by presence" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      [@customer_role],
      "user:testuser"
    )

    assert Map.has_key?(Presence.list("role:customer"), "testuser")
    Process.unlink(sock.channel_pid)
    close sock
    assert !Map.has_key?(Presence.list("role:customer"), "testuser")
  end
  
  test "an authorized user should be able to list presences" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      [@customer_role],
      "user:testuser"
    )

    assert Map.has_key?(Channel.channels_list("user:testuser"), "testuser")
    leave sock
  end
end
