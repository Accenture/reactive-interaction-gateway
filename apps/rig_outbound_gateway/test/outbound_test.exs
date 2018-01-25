defmodule RigOutboundGateway.OutboundTest do
  @moduledoc false
  use ExUnit.Case, async: true

  setup do
    stub =
      Stubr.stub!(
        [
          channel_name: fn id -> "user:#{id}" end,
          broadcast: fn _, _, _, _ -> :ok end
        ],
        call_info: true
      )

    [stub: stub]
  end

  describe "message delivery" do
    test "declines message if user id field is missing", %{stub: stub} do
      value = %{"payload" => "myMessage"}

      assert {:error, %KeyError{}} =
               RigOutboundGateway.send(value, &stub.channel_name/1, &stub.broadcast/4)

      assert not Stubr.called?(stub, :channel_name)
      assert not Stubr.called?(stub, :broadcast)
    end

    test "broadcasts valid messages", %{stub: stub} do
      user_field = Confex.get_env(:rig, RigOutboundGateway)[:message_user_field]
      assert String.valid?(user_field) and String.length(user_field) > 0
      value = %{"#{user_field}" => "myUser", "payload" => "myMessage"}

      assert :ok = RigOutboundGateway.send(value, &stub.channel_name/1, &stub.broadcast/4)

      assert Stubr.called_with_exactly?(stub, :channel_name, [["myUser"]])

      assert Stubr.called_with_exactly?(stub, :broadcast, [
               [Rig.PubSub, "user:myUser", "message", value]
             ])
    end
  end
end
