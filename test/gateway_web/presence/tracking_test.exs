defmodule GatewayWeb.Presence.TrackingTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use GatewayWeb.ChannelCase
  alias GatewayWeb.Presence
  alias GatewayWeb.Presence.Channel

  test "an authorized user should be able to list presences" do
    assert {:ok, _response, sock} = subscribe_and_join_user(
      "testuser",
      [@customer_role],
      "user:testuser"
    )

    assert Map.has_key?(Channel.channels_list("user:testuser"), "testuser")
    leave sock
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
end
