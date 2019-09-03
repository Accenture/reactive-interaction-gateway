defmodule Rig.PubSubTest do
  @moduledoc false
  use ExUnit.Case

  alias Phoenix.PubSub
  alias Rig.PubSub, as: SUT

  test "the PubSub server is running" do
    assert :ok = PubSub.subscribe(SUT, "user:123")
    assert {:messages, []} = Process.info(self(), :messages)
    assert :ok = PubSub.broadcast(SUT, "user:123", {:hi})
    assert {:messages, [{:hi}]} = Process.info(self(), :messages)
  end
end
