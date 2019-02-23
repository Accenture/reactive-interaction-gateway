defmodule RIG.Subscriptions.Parser.JSONTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest RIG.Subscriptions.Parser.JSON

  alias Result

  alias Rig.Subscription
  alias RIG.Subscriptions.Parser.JSON, as: SUT

  test "In a JSON string, valid subscriptions are decoded as such, while ill-formed subscriptions are turned into errors." do
    input = ~S"""
    [
      {"eventType": "greeting", "oneOf": []},
      {"eventType": 123, "oneOf": []}
    ]
    """

    assert [good, bad] = SUT.from_json(input)
    assert %Subscription{} = Result.unwrap(good)
    assert Result.err?(bad)
  end

  test "A non-JSON string leads to a decoding error." do
    input = ~S"""
    this causes a decoding error.
    [
      {"eventType": "greeting", "oneOf": []},
      {"eventType": 123, "oneOf": []},
    ]
    """

    assert [error] = SUT.from_json(input)
    assert %Jason.DecodeError{} = Result.unwrap_err(error)
  end
end
