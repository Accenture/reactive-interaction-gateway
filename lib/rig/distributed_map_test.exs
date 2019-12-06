defmodule RIG.DistributedMapTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest RIG.DistributedMap

  alias RIG.DistributedMap

  test "starting a map with no OTP name set" do
    {:ok, pid} = DistributedMap.start_link(MyMap)
    :ok = DistributedMap.add(pid, "foo", "bar", 60)
    :ok = DistributedMap.add(pid, "foo", "baz", 60)
    ["bar", "baz"] = DistributedMap.get(pid, "foo")
    :ok = GenServer.stop(pid)
  end

  test "starting a map with an OTP name and refer to it by that name" do
    {:ok, _pid} = DistributedMap.start_link(MyMap, name: TheName)
    :ok = DistributedMap.add(TheName, "foo", "bar", 60)
    true = DistributedMap.has?(TheName, "foo")
    :ok = GenServer.stop(TheName)
  end

  test "that a record expires" do
    {:ok, _pid} = DistributedMap.start_link(MyMap, name: MyMap)
    false = DistributedMap.has?(MyMap, "foo")
    :ok = DistributedMap.add(MyMap, "foo", "bar", 60)
    true = DistributedMap.has?(MyMap, "foo")
    false = DistributedMap.has?(MyMap, "foo", shift_time_s: 61)
    :ok = GenServer.stop(MyMap)
  end

  test "adding a second process to the map" do
    key = "foo"
    value = "bar"

    {:ok, a} = DistributedMap.start_link(TestMap)
    :ok = DistributedMap.add(a, key, value, 60)

    # Adding a new process to the test map will replicate the record:
    {:ok, b} = DistributedMap.start_link(TestMap)
    # We call `add` here to make sure the sync has completed already:
    DistributedMap.add(b, "dummy", "x")
    # The new process now sees the record as well:
    true = DistributedMap.has?(b, key)

    # An unrelated map is not connected:
    {:ok, c} = DistributedMap.start_link(DifferentTestMap)
    DistributedMap.add(c, "dummy", "y")
    false = DistributedMap.has?(c, key)

    # Stopping the original instance does not affect the second one:
    GenServer.stop(a)
    true = DistributedMap.has?(b, key)

    # Stop the remaining servers:
    GenServer.stop(b)
    GenServer.stop(c)
  end
end
