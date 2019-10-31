defmodule CloudEventTest do
  @moduledoc false
  use ExUnit.Case
  alias RigCloudEvents.CloudEvent
  doctest CloudEvent

  alias Jason

  test "An event is parsed as type CloudEvents 0.1 according to the spec." do
    event = %{}
    assert {:error, _} = event |> Jason.encode!() |> CloudEvent.parse()
    event = event |> Map.put("cloudEventsVersion", "0.1")
    assert {:error, _} = event |> Jason.encode!() |> CloudEvent.parse()
    event = event |> Map.put("eventType", "some-type")
    assert {:error, _} = event |> Jason.encode!() |> CloudEvent.parse()
    event = event |> Map.put("source", "some-source")
    assert {:error, _} = event |> Jason.encode!() |> CloudEvent.parse()
    event = event |> Map.put("eventID", "some-id")

    assert {:ok, %CloudEvent{json: json, parsed: parsed}} =
             event |> Jason.encode!() |> CloudEvent.parse()

    refute is_nil(json)
    refute is_nil(parsed)
  end

  test "An event is parsed as type CloudEvents 0.2 according to the spec." do
    event = %{}
    assert {:error, _} = event |> Jason.encode!() |> CloudEvent.parse()
    event = event |> Map.put("specversion", "0.2")
    assert {:error, _} = event |> Jason.encode!() |> CloudEvent.parse()
    event = event |> Map.put("type", "some-type")
    assert {:error, _} = event |> Jason.encode!() |> CloudEvent.parse()
    event = event |> Map.put("source", "some-source")
    assert {:error, _} = event |> Jason.encode!() |> CloudEvent.parse()
    event = event |> Map.put("id", "some-id")

    assert {:ok, %CloudEvent{json: json, parsed: parsed}} =
             event |> Jason.encode!() |> CloudEvent.parse()

    refute is_nil(json)
    refute is_nil(parsed)
  end

  test "An event is parsed as type CloudEvents 1.0 according to the spec." do
    # The official example:
    event_json = """
    {
      "specversion" : "1.0",
      "type" : "com.github.pull.create",
      "source" : "https://github.com/cloudevents/spec/pull",
      "subject" : "123",
      "id" : "A234-1234-1234",
      "time" : "2018-04-05T17:31:00Z",
      "comexampleextension1" : "value",
      "comexampleothervalue" : 5,
      "datacontenttype" : "text/xml",
      "data" : "<much wow=\"xml\"/>"
    }
    """

    assert {:ok, %CloudEvent{json: ^event_json} = cloud_event} = CloudEvent.parse(event_json)
    assert CloudEvent.specversion!(cloud_event) == "1.0"
    assert CloudEvent.id!(cloud_event) == "A234-1234-1234"
    assert CloudEvent.type!(cloud_event) == "com.github.pull.create"
  end
end
