defmodule RIG.Subscriptions.Parser.JSONTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest RIG.Subscriptions.Parser.JSON

  alias Result

  alias RIG.Subscriptions.Parser.JSON, as: SUT

  test "Good subscriptions are decoded as expected." do
    # Two good subscriptions:
    input = ~S"""
    [
      {"eventType": "foo", "oneOf": [{"a": "b"}]},
      {"eventType": "bar", "oneOf": []}
    ]
    """

    assert {:ok, subscriptions} = SUT.from_json(input)
    assert [foo, bar] = subscriptions
    assert %{event_type: "foo", constraints: [%{"a" => "b"}]} = foo
    assert %{event_type: "bar", constraints: []} = bar
  end

  test "Either all subscriptions are decoded, or an error is returned." do
    # Two subscriptions, a good and a bad one:
    input = ~S"""
    [
      {"eventType": "greeting", "oneOf": []},
      {"eventType": 123, "oneOf": []}
    ]
    """

    # Since one of them doesn't contain a valid eventType, we get back an error:
    assert {:error, _} = SUT.from_json(input)
  end

  test "A non-JSON string leads to a decoding error." do
    input = ~S"""
    this causes a decoding error.
    [
      {"eventType": "greeting", "oneOf": []},
      {"eventType": 123, "oneOf": []},
    ]
    """

    assert {:error, _} = SUT.from_json(input)
  end
end
