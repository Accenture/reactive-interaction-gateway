defmodule RigInboundGatewayWeb.EventBufferTest do
  use ExUnit.Case, async: true

  alias RigCloudEvents.CloudEvent
  alias RigInboundGatewayWeb.EventBuffer

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
    assert EventBuffer.capacity(buffer) == 2
    assert EventBuffer.all_events(buffer) == []

    # We add a first event:
    first_event = new_event("first")
    buffer = EventBuffer.add_event(buffer, first_event)
    # The event is in the buffer:
    assert EventBuffer.all_events(buffer) == [first_event]
    # There is no more recent event yet:
    {:ok, [events: events, last_event_id: last_event_id]} =
      EventBuffer.events_since(buffer, "first")

    assert events == []
    assert last_event_id == "first"

    # We add a second event to the buffer:
    second_event = new_event("second")
    buffer = EventBuffer.add_event(buffer, second_event)
    # Both events are now in the buffer:
    assert EventBuffer.all_events(buffer) == [first_event, second_event]
    # "second" is now more recent than "first", but there is no event newer than "second":
    {:ok, [events: events, last_event_id: last_event_id]} =
      EventBuffer.events_since(buffer, "first")

    assert events == [second_event]
    assert last_event_id == "second"

    {:ok, [events: events, last_event_id: last_event_id]} =
      EventBuffer.events_since(buffer, "second")

    assert events == []
    assert last_event_id == "second"

    # Adding a third event should remove the first one:
    third_event = new_event("third")
    buffer = EventBuffer.add_event(buffer, third_event)

    # The first event is no longer in the buffer, due to max size of the buffer:
    assert EventBuffer.all_events(buffer) == [second_event, third_event]
    # "third" is now more recent than "second", but there is no event newer than "third":
    {:ok, [events: events, last_event_id: last_event_id]} =
      EventBuffer.events_since(buffer, "second")

    assert events == [third_event]
    assert last_event_id == "third"

    {:ok, [events: events, last_event_id: last_event_id]} =
      EventBuffer.events_since(buffer, "third")

    assert events == []
    assert last_event_id == "third"

    # Since "first" is no longer in the buffer, _all_ events are newer than "first":
    {:no_such_event, [not_found_id: not_found_id, last_event_id: last_event_id]} =
      EventBuffer.events_since(buffer, "first")

    assert not_found_id == "first"
    assert last_event_id == "third"

    # The capacity hasn't changed during the modifications:
    assert EventBuffer.capacity(buffer) == 2
  end
end
