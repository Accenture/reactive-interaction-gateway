defmodule CloudEvents_0_2_Test do
  # credo:disable-for-previous-line Credo.Check.Readability.ModuleNames
  @moduledoc false
  use ExUnit.Case

  alias CloudEvents
  alias CloudEvents_0_2

  @valid_cloud_event %{
    "specversion" => "0.2",
    "type" => "com.github.pull.create",
    "source" => "https://github.com/cloudevents/spec/pull/123",
    "id" => "A234-1234-1234",
    "time" => "2018-04-05T17:31:00Z",
    "comexampleextension1" => "value",
    "comexampleextension2" => %{"othervalue" => 5},
    "contenttype" => "text/xml",
    "data" => "<much wow=\"xml\"/>"
  }

  test "A valid CloudEvent in version 0.2 is parsed." do
    assert {:ok, event} = CloudEvents.parse(@valid_cloud_event)
    assert event.id == "A234-1234-1234"
    assert event.time == Timex.parse!("2018-04-05T17:31:00Z", "{RFC3339}")
    assert event.type == "com.github.pull.create"
    assert event.source == "https://github.com/cloudevents/spec/pull/123"
  end

  test "Parsing fails if there is no event type." do
    event = Map.delete(@valid_cloud_event, "type")
    assert {:error, :illegal_field, {:type, :missing}} = CloudEvents.parse(event)
  end

  test "Parsing fails if the event type is not a string." do
    event = Map.put(@valid_cloud_event, "type", nil)
    assert {:error, :illegal_field, {:type, :not_a_string}} = CloudEvents.parse(event)
  end

  test "Parsing fails if the event type is empty." do
    event = Map.put(@valid_cloud_event, "type", "")
    assert {:error, :illegal_field, {:type, :empty}} = CloudEvents.parse(event)
  end
end
