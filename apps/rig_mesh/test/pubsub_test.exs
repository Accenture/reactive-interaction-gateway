defmodule RigMesh.PubSubTest do
  use ExUnit.Case

  alias Phoenix.PubSub

  test "the PubSub server is running" do
    assert :ok = PubSub.subscribe(RigMesh.PubSub, "user:123")
    assert [] = Process.info(self())[:messages]
    assert :ok = PubSub.broadcast(RigMesh.PubSub, "user:123", {:hi})
    assert [{:hi}] = Process.info(self())[:messages]
  end
end
