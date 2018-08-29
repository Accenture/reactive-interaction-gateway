defmodule Rig.DistributedSetTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest Rig.DistributedSet

  alias Rig.DistributedSet

  test "starting a set with no OTP name set" do
    {:ok, pid} = DistributedSet.start_link(MySet)
    :ok = DistributedSet.add(pid, "foo", 60)
    true = DistributedSet.has?(pid, "foo")
    :ok = GenServer.stop(pid)
  end

  test "starting a set with an OTP name and refer to it by that name" do
    {:ok, _pid} = DistributedSet.start_link(MySet, name: TheName)
    :ok = DistributedSet.add(TheName, "foo", 60)
    true = DistributedSet.has?(TheName, "foo")
    :ok = GenServer.stop(TheName)
  end

  test "that a record expires" do
    {:ok, _pid} = DistributedSet.start_link(MySet, name: MySet)
    false = DistributedSet.has?(MySet, "foo")
    :ok = DistributedSet.add(MySet, "foo", 60)
    true = DistributedSet.has?(MySet, "foo")
    false = DistributedSet.has?(MySet, "foo", shift_time_s: 61)
    :ok = GenServer.stop(MySet)
  end

  test "adding a second process to the set" do
    key = "foo"

    {:ok, a} = DistributedSet.start_link(TestSet)
    :ok = DistributedSet.add(a, key, 60)

    # Adding a new process to the test set will replicate the record:
    {:ok, b} = DistributedSet.start_link(TestSet)
    # We call `add` here to make sure the sync has completed already:
    DistributedSet.add(b, "dummy")
    # The new process now sees the record as well:
    true = DistributedSet.has?(b, key)

    # An unrelated set is not connected:
    {:ok, c} = DistributedSet.start_link(DifferentTestSet)
    DistributedSet.add(c, "dummy")
    false = DistributedSet.has?(c, key)

    # Stopping the original instance does not affect the second one:
    GenServer.stop(a)
    true = DistributedSet.has?(b, key)

    # Stop the remaining servers:
    GenServer.stop(b)
    GenServer.stop(c)
  end
end
