defmodule Rig.EventFilter.ServerTest.MatchSpec.ConfigUpdaterTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Rig.EventFilter.MatchSpec.ConfigUpdater, as: SUT

  test "adds a nil value (=wildcard) for each additional field" do
    n_old_fields = 1
    n_new_fields = 3
    [pid, exp] = [self(), 123]

    old_subscription = {pid, exp, "old field"}
    expected_new_subscription = {pid, exp, "old field", nil, nil}

    ms = SUT.match_spec(n_old_fields, n_new_fields)

    assert {:ok, expected_new_subscription} == :ets.test_ms(old_subscription, ms)
  end
end
