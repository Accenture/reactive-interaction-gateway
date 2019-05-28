defmodule EventBufferTest do
  use ExUnit.Case, async: true

  alias RigInboundGatewayWeb.EventBuffer

  test "New EventBuffer starts with no events" do
    buffer = EventBuffer.new(5)
    assert buffer.events === []
    assert buffer.max_size === 5
    assert buffer.write_pointer === 0
    assert buffer.read_pointer === 0
  end

  test "returns events as they are added" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    assert buffer.write_pointer === 1
    assert buffer.read_pointer === 0
    {:ok, buffer, value} = EventBuffer.read(buffer)
    assert value === 1
    assert buffer.write_pointer === 1
    assert buffer.read_pointer === 1
  end

  test "An exceeding write overwrites the oldest value - edge-case no read at all" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    buffer = EventBuffer.write(buffer, 2)
    buffer = EventBuffer.write(buffer, 3)
    buffer = EventBuffer.write(buffer, 4)
    buffer = EventBuffer.write(buffer, 5)
    buffer = EventBuffer.write(buffer, 6)
    assert buffer.events === [6, 2, 3, 4, 5]
  end

  test "An exceeding write overwrites the oldest value" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    {:ok, buffer, _value} = EventBuffer.read(buffer)
    buffer = EventBuffer.write(buffer, 2)
    buffer = EventBuffer.write(buffer, 3)
    buffer = EventBuffer.write(buffer, 4)
    buffer = EventBuffer.write(buffer, 5)
    buffer = EventBuffer.write(buffer, 6)
    assert buffer.events === [6, 2, 3, 4, 5]
  end

  test "Overtaking write, also pushes the read" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    buffer = EventBuffer.write(buffer, 2)
    buffer = EventBuffer.write(buffer, 3)
    buffer = EventBuffer.write(buffer, 4)
    buffer = EventBuffer.write(buffer, 5)
    buffer = EventBuffer.write(buffer, 6)
    assert buffer.write_pointer === 1
    assert buffer.read_pointer === 2
    {:ok, buffer, value} = EventBuffer.read(buffer)
    assert value === 3
    assert buffer.read_pointer === 3
    {:ok, buffer, value} = EventBuffer.read(buffer)
    assert value === 4
    assert buffer.read_pointer === 4
  end

  test "empty eventbuffer provides an empty list" do
    buffer = EventBuffer.new(5)
    {:ok, _buffer, value} = EventBuffer.read(buffer)
    assert value === []
  end

  test "if all events are read provide an empty list" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    {:ok, buffer, value} = EventBuffer.read(buffer)
    assert value === 1
    {:ok, _buffer, value} = EventBuffer.read(buffer)
    assert value === []
  end

  test "read_all provides a list of all unread events" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    buffer = EventBuffer.write(buffer, 2)
    buffer = EventBuffer.write(buffer, 3)
    buffer = EventBuffer.write(buffer, 4)
    buffer = EventBuffer.write(buffer, 5)
    {:ok, _buffer, values} = EventBuffer.read_all(buffer)
    assert values === [1, 2, 3, 4, 5]
  end

  test "read_all also provides a list of all unread events around the horn" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    buffer = EventBuffer.write(buffer, 2)
    buffer = EventBuffer.write(buffer, 3)
    buffer = EventBuffer.write(buffer, 4)
    buffer = EventBuffer.write(buffer, 5)
    {:ok, buffer, _value} = EventBuffer.read(buffer)
    {:ok, buffer, _value} = EventBuffer.read(buffer)
    buffer = EventBuffer.write(buffer, 6)
    buffer = EventBuffer.write(buffer, 7)
    {:ok, _buffer, values} = EventBuffer.read_all(buffer)
    assert values === [4, 5, 6, 7]
  end

  test "read_at provides the value from the given position, ignoring current read_pointer" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    buffer = EventBuffer.write(buffer, 2)
    buffer = EventBuffer.write(buffer, 3)
    buffer = EventBuffer.write(buffer, 4)
    buffer = EventBuffer.write(buffer, 5)
    {:ok, buffer, value} = EventBuffer.read(buffer)
    assert value === 1
    {:ok, _buffer, value} = EventBuffer.read_at(buffer, 0)
    assert value === 1
  end

  test "read_at overwrites current read_pointer" do
    buffer = EventBuffer.new(5)
    buffer = EventBuffer.write(buffer, 1)
    buffer = EventBuffer.write(buffer, 2)
    buffer = EventBuffer.write(buffer, 3)
    buffer = EventBuffer.write(buffer, 4)
    buffer = EventBuffer.write(buffer, 5)
    {:ok, buffer, _value} = EventBuffer.read(buffer)
    {:ok, buffer, _value} = EventBuffer.read(buffer)
    assert buffer.read_pointer === 2
    {:ok, buffer, _value} = EventBuffer.read_at(buffer, 0)
    assert buffer.read_pointer === 1
  end
end
