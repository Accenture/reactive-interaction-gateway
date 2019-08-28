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
end
