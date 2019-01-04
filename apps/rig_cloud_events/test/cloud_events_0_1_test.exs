defmodule CloudEvents_0_1_Test do
  # credo:disable-for-previous-line Credo.Check.Readability.ModuleNames
  @moduledoc false
  use ExUnit.Case

  alias CloudEvents
  alias CloudEvents_0_1

  @valid_cloud_event %{
    "cloudEventsVersion" => "0.1",
    "eventID" => "first-event",
    "eventTime" => "2018-08-21T09:11:27.614970+00:00",
    "eventType" => "greeting",
    "source" => "unit-test"
  }

  test "A valid CloudEvent in version 0.1 is parsed." do
    assert {:ok, event} = CloudEvents.parse(@valid_cloud_event)
    assert event.event_id == "first-event"
    assert event.event_time == Timex.parse!("2018-08-21T09:11:27.614970+00:00", "{RFC3339}")
    assert event.event_type == "greeting"
    assert event.source == "unit-test"
  end

  test "Parsing fails if there is no event type." do
    event = Map.delete(@valid_cloud_event, "eventType")
    assert {:error, :illegal_field, {:event_type, :missing}} = CloudEvents.parse(event)
  end

  test "Parsing fails if the event type is not a string." do
    event = Map.put(@valid_cloud_event, "eventType", nil)
    assert {:error, :illegal_field, {:event_type, :not_a_string}} = CloudEvents.parse(event)
  end

  test "Parsing fails if the event type is empty." do
    event = Map.put(@valid_cloud_event, "eventType", "")
    assert {:error, :illegal_field, {:event_type, :empty}} = CloudEvents.parse(event)
  end
end
