defmodule Rig.EventFilter.ServerTest.MatchSpec.SubscriptionMatcherTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Rig.EventFilter.MatchSpec.SubscriptionMatcher, as: SUT

  test "subscription match: catch-all when no constraint fields" do
    fields = []
    get_value_in_event = fn _field -> nil end
    pid = self()

    subscriptions = [
      {pid, 123}
    ]

    ms = SUT.match_spec(fields, get_value_in_event)

    for sub <- subscriptions do
      assert {:ok, pid} == :ets.test_ms(sub, ms)
    end
  end

  test "subscription match with constraints" do
    fields = [:foo, :bar]

    get_value_in_event = fn
      :foo -> "a foo value"
      :bar -> nil
    end

    [pid, exp] = [self(), 123]

    subscription_spec = [
      # matches anything:
      {{pid, exp, nil, nil}, :match},
      # foo must match, but bar doesn't matter:
      {{pid, exp, "a foo value", nil}, :match},
      # foo AND bar must match (which is not the case):
      {{pid, exp, "a foo value", "a bar value"}, :no_match},
      # only foo must match (but doesn't):
      {{pid, exp, "some other foo value", nil}, :no_match}
    ]

    ms = SUT.match_spec(fields, get_value_in_event)

    for {subscription, match_expectation} = spec <- subscription_spec do
      {:ok, result} = :ets.test_ms(subscription, ms)

      case match_expectation do
        :match ->
          case result do
            ^pid -> :ok
            _ -> bail(spec, result)
          end

        :no_match ->
          case result do
            false -> :ok
            _ -> bail(spec, result)
          end
      end
    end
  end

  defp bail({subscription, :match}, result),
    do: assert(false, "failed to match #{inspect(subscription)} -> #{inspect(result)}")

  defp bail({subscription, :no_match}, result),
    do: assert(false, "matched unexpectedly #{inspect(subscription)} -> #{inspect(result)}")
end
