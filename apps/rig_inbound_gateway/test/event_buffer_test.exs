defmodule EventBufferTest do
  use ExUnit.Case, async: true

  alias RigInboundGatewayWeb.EventBuffer
  alias RigCloudEvents.CloudEvent

  defp new_event(id) do
    {:ok, event} =
      CloudEvent.parse("""
        {"specversion": "0.2", "id": "#{id}", "type": "test-event"}
      """)

    event
  end

  test "Adding events leaves the capacity unchanged and overwrites old events as soon as the buffer is filled up to its capacity." do
    # We create a new buffer that holds at most 2 events:
    buffer = EventBuffer.new(2)
    assert buffer |> EventBuffer.capacity() == 2
    assert buffer |> EventBuffer.all_events() == []

    # We add a first event:
    first_event = new_event("first")
    buffer = buffer |> EventBuffer.add_event(first_event)
    # The event is in the buffer:
    assert buffer |> EventBuffer.all_events() == [first_event]
    # There is no more recent event yet:
    {:ok, [events: events, last_event_id: last_event_id]} =
      buffer |> EventBuffer.events_since("first")

    assert events == []
    assert last_event_id == "first"

    # We add a second event to the buffer:
    second_event = new_event("second")
    buffer = buffer |> EventBuffer.add_event(second_event)
    # Both events are now in the buffer:
    assert buffer |> EventBuffer.all_events() == [first_event, second_event]
    # "second" is now more recent than "first", but there is no event newer than "second":
    {:ok, [events: events, last_event_id: last_event_id]} =
      buffer |> EventBuffer.events_since("first")

    assert events == [second_event]
    assert last_event_id == "second"

    {:ok, [events: events, last_event_id: last_event_id]} =
      buffer |> EventBuffer.events_since("second")

    assert events == []
    assert last_event_id == "second"

    # Adding a third event should remove the first one:
    third_event = new_event("third")
    buffer = buffer |> EventBuffer.add_event(third_event)

    # The first event is no longer in the buffer (all_events doesn't provide the correct order tho)
    assert buffer |> EventBuffer.all_events() == [third_event, second_event]
    # "third" is now more recent than "second", but there is no event newer than "third":
    {:ok, [events: events, last_event_id: last_event_id]} =
      buffer |> EventBuffer.events_since("second")

    assert events == [third_event]
    assert last_event_id == "third"

    {:ok, [events: events, last_event_id: last_event_id]} =
      buffer |> EventBuffer.events_since("third")

    assert events == []
    assert last_event_id == "third"

    # Since "first" is no longer in the buffer, _all_ events are newer than "first":
    {:no_such_event, [not_found_id: not_found_id, last_event_id: last_event_id]} =
      buffer |> EventBuffer.events_since("first")

    assert not_found_id == "first"
    assert last_event_id == "third"

    # The capacity hasn't changed during the modifications:
    assert EventBuffer.capacity(buffer) == 2
  end
end
