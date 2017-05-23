defmodule Gateway.PresenceChannelTest do
  use ExUnit.Case, async: true
  use Gateway.ChannelCase
  alias Gateway.PresenceChannel

  test "an user connecting to her own topic works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      ["customer"],
      "presence:testuser"
    )
    leave sock
  end
  
  test "an user connecting to someone else's topic with not authorized role fails" do
    assert {:error, _message} = subscribe_and_join_user(
      "foo-user",
      ["customer"],
      "presence:bar-user"
    )
  end
  
  test "an user connecting to someone else's topic with authorized role works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "foo-user",
      ["support"],
      "presence:testuser"
    )
    leave sock
  end
  
  test "an user connecting to role specific topic with authorised role works" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "foo-user",
      ["support"],
      "presence.role:customer"
    )
    leave sock
  end
  
  test "an user connecting to role specific topic without authorised role fails" do
    assert {:error, _message} = subscribe_and_join_user(
      "foo-user",
      ["customer"],
      "presence.role:customer"
    )
  end
  
  test "an user connecting to his own channel should trigger broadcast to all role based channels" do
    @endpoint.subscribe("presence.role:role1")
    @endpoint.subscribe("presence.role:role2")
  
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      ["role1", "role2"],
      "presence:testuser"
    )

    assert_broadcast("role1-joined", %{})
    assert_broadcast("role2-joined", %{})
    leave sock

    @endpoint.unsubscribe("presence.role:role1")
    @endpoint.unsubscribe("presence.role:role2")
  end
  
  test "an user leaving his own channel should trigger broadcast to all role based channels" do
    @endpoint.subscribe("presence.role:role1")
    @endpoint.subscribe("presence.role:role2")
    
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      ["role1", "role2"],
      "presence:testuser"
    )
    Process.unlink(sock.channel_pid)
    leave sock

    assert_broadcast("role1-left", %{})
    assert_broadcast("role2-left", %{})

    @endpoint.unsubscribe("presence.role:role1")
    @endpoint.unsubscribe("presence.role:role2")
  end
  
  test "an authorised user subscribed to role based channel should receive join broadcast" do
    assert {:ok, _response, sock_support} = subscribe_and_join_user(
      "first.support",
      ["support"],
      "presence.role:customer"
    )

    assert {:ok, _response, sock_customer} = subscribe_and_join_user(
      "first.user",
      ["customer"],
      "presence:first.user"
    )

    Process.unlink(sock_support.channel_pid)
    Process.unlink(sock_customer.channel_pid)
    leave sock_support
    leave sock_customer

    assert_receive(%Phoenix.Socket.Message{event: "customer-joined", payload: %{}})
  end
  
  test "an authorised user subscribed to role based channel should receive leave broadcast" do
    assert {:ok, _response, sock_support} = subscribe_and_join_user(
      "first.support",
      ["support"],
      "presence.role:customer"
    )

    assert {:ok, _response, sock_customer} = subscribe_and_join_user(
      "first.user",
      ["customer"],
      "presence:first.user"
    )
  
    Process.unlink(sock_customer.channel_pid)
    Process.unlink(sock_support.channel_pid)
    close sock_customer
    leave sock_support
  
    assert_receive(%Phoenix.Socket.Message{event: "customer-left", payload: %{}})
  end

  defp subscribe_and_join_user(username, roles, topic) do
    token_info_customer = %{"username" => username, "role" => roles}
    # {:ok, _response, sock_customer} =
    socket("", %{user_info: token_info_customer})
    |> subscribe_and_join(PresenceChannel, topic)
  end
end
