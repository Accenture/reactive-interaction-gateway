defmodule Gateway.PresenceChannelTest do
  use ExUnit.Case, async: true
  use Gateway.ChannelCase
  alias Gateway.PresenceChannel

  test "a user connecting to her own topic works" do
    token_info = %{"username" => "testuser"}
    assert {:ok, _response, sock} =
      socket("", %{user_info: token_info})
      |> subscribe_and_join(PresenceChannel, "presence:testuser")
    leave sock
  end

  test "a user connecting to someone else's topic fails" do
    token_info = %{"username" => "foo-user"}
    assert {:error, _message} =
      socket("", %{user_info: token_info})
      |> subscribe_and_join(PresenceChannel, "presence:bar-user")
  end
end
