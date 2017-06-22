defmodule Gateway.BlacklistTest do
  require Logger
  use ExUnit.Case, async: false
  alias Gateway.Blacklist
  import Gateway.Blacklist, only: [add_jti: 4, contains_jti?: 2]

  setup do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    tracker = Stubr.stub!([
        # @callback track(jti: String.t, expiry: Timex.DateTime.t) :: {:ok, String.t}
        track: fn jti, expiry ->
          Logger.debug "Tracker Stub :track jti=#{inspect jti} expiry=#{inspect expiry}"
          # Mimic the "cannot track more than once" behaviour:
          already_tracked? = Agent.get(agent, fn
            list -> list |> Enum.find(fn {key, _} -> key == jti end)
          end) != nil
          if already_tracked? do
            {:error, :already_tracked}
          else
            Agent.update(agent, fn
              list -> [{jti, %{expiry: expiry}} | list]
            end)
            {:ok, 'some_phx_ref'}
          end
        end,
        # @callback untrack(jti: String.t) :: :ok
        untrack: fn jti ->
          Logger.debug "Tracker Stub :untrack jti=#{inspect jti}"
          Agent.update(agent, fn
            list -> list |> Enum.filter(fn {key, _} -> key != jti end)
          end)
          :ok
        end,
        # @callback list() :: [{String.t, %{optional(String.t) => String.t}}]
        list: fn ->
          Logger.debug "Tracker Stub :list"
          Agent.get(agent, fn
            list -> list
          end)
        end,
        # @callback find(jti: String.t) :: {String.t, %{optional(String.t) => String.t}} | nil
        find: fn jti ->
          Logger.debug "Tracker Stub :find jti=#{inspect jti}"
          Agent.get(agent, fn
            list -> list |> Enum.find(fn {key, _} -> key == jti end)
          end)
        end,
      ],
      behaviour: Gateway.Blacklist.Tracker.TrackerBehaviour,
      call_info: true,
    )
    [tracker: tracker]
  end

  test "blacklisting a JTI causes it to be tracked", ctx do
    {:ok, blacklist} = Blacklist.start_link(ctx.tracker, name: nil)
    refute blacklist |> contains_jti?("FOO_JTI")
    assert ctx.tracker |> Stubr.called_with?(:find, ["FOO_JTI"])
    refute blacklist |> contains_jti?("BAR_JTI")

    expiry = Timex.now() |> Timex.shift(days: 1)
    # Also tests that chaining works:
    blacklist
    |> add_jti("FOO_JTI", expiry, _listener = nil)
    |> add_jti("BAR_JTI", expiry, _listener = nil)

    assert blacklist |> contains_jti?("FOO_JTI")
    assert blacklist |> contains_jti?("BAR_JTI")
    assert ctx.tracker |> Stubr.called_twice?(:track)
    refute ctx.tracker |> Stubr.called?(:untrack)
  end

  test "a JTI expiry removes it from the blacklist", ctx do
    {:ok, blacklist} = Blacklist.start_link(ctx.tracker, name: nil)

    jti = "FOO_JTI"
    expiry = Timex.now() |> Timex.shift(seconds: -1)
    blacklist |> add_jti(jti, expiry, _listener = self())

    assert_receive {:expired, ^jti}
    refute blacklist |> contains_jti?(jti)
    assert ctx.tracker |> Stubr.called_once?(:track)
    assert ctx.tracker |> Stubr.called_once?(:untrack)
  end

  test "adding a JTI more than once is a no-op", ctx do
    {:ok, blacklist} = Blacklist.start_link(ctx.tracker, name: nil)

    future = Timex.now() |> Timex.shift(days: 1)
    blacklist
    |> add_jti("FOO_JTI", future, _listener = nil)
    |> add_jti("FOO_JTI", future, _listener = nil)  # same again

    assert blacklist |> contains_jti?("FOO_JTI")
    assert ctx.tracker |> Stubr.called_twice?(:track)
    assert ctx.tracker.list() |> length == 1
  end

  test "after a restart, stale records are expired", ctx do
    past = Timex.now() |> Timex.shift(weeks: -1)
    future = Timex.now() |> Timex.shift(weeks: 1)
    ctx.tracker.track("foo", past)    # should be expired
    ctx.tracker.track("bar", past)    # should be expired
    ctx.tracker.track("baz", future)  # should be kept

    {:ok, blacklist} = Blacklist.start_link(ctx.tracker, name: nil)

    refute blacklist |> contains_jti?("foo")
    refute blacklist |> contains_jti?("bar")
    assert blacklist |> contains_jti?("baz")
  end

  # defp assert_added(jti) do
  #   # sent by Gateway.PubSub by broadcast from PresenceHandler
  #   assert_receive {:join, ^jti, _}, 10_000
  # end
end
