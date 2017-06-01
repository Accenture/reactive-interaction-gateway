defmodule Gateway.PresenceChannelTest do
  use ExUnit.Case, async: true
  use Gateway.ChannelCase
  alias Gateway.PresenceChannel
  alias Gateway.Presence
  
  @support_role "support"
  @customer_role "customer"

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

  defp subscribe_and_join_user(username, roles, topic) do
    token_info_customer = %{"username" => username, "role" => roles, "jti" => "123"}
    socket("", %{user_info: token_info_customer})
    |> subscribe_and_join(PresenceChannel, topic)
  end
end
