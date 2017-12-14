defmodule RigInboundGateway.BlacklistTest do
  @moduledoc false
  use ExUnit.Case, async: true
  require Logger
  alias RigInboundGateway.Blacklist
  import RigInboundGateway.Blacklist, only: [add_jti: 4, contains_jti?: 2]

  describe "a blacklist" do
    setup [:with_tracker_mock]

    test "tracks an added jti", ctx do
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

    test "drops a jti after expiry", ctx do
      {:ok, blacklist} = Blacklist.start_link(ctx.tracker, name: nil)

      jti = "FOO_JTI"
      expiry = Timex.now() |> Timex.shift(seconds: -1)
      blacklist |> add_jti(jti, expiry, _listener = self())

      assert_receive {:expired, ^jti}
      refute blacklist |> contains_jti?(jti)
      assert ctx.tracker |> Stubr.called_once?(:track)
      assert ctx.tracker |> Stubr.called_once?(:untrack)
    end

    test "allows adding a jti more than once without effect", ctx do
      {:ok, blacklist} = Blacklist.start_link(ctx.tracker, name: nil)

      future = Timex.now() |> Timex.shift(days: 1)
      # same again
      blacklist
      |> add_jti("FOO_JTI", future, _listener = nil)
      |> add_jti("FOO_JTI", future, _listener = nil)

      assert blacklist |> contains_jti?("FOO_JTI")
      assert ctx.tracker |> Stubr.called_twice?(:track)
      assert ctx.tracker.list() |> length == 1
    end

    test "expires stale records on startup", ctx do
      past = Timex.now() |> Timex.shift(weeks: -1)
      future = Timex.now() |> Timex.shift(weeks: 1)
      # should be expired
      ctx.tracker.track("foo", past)
      # should be expired
      ctx.tracker.track("bar", past)
      # should be kept
      ctx.tracker.track("baz", future)

      {:ok, blacklist} = Blacklist.start_link(ctx.tracker, name: nil)

      refute blacklist |> contains_jti?("foo")
      refute blacklist |> contains_jti?("bar")
      assert blacklist |> contains_jti?("baz")
    end
  end

  defp with_tracker_mock(_ctx) do
    {:ok, agent} = Agent.start_link(fn -> [] end)

    tracker =
      Stubr.stub!(
        [
          # @callback track(jti: String.t, expiry: Timex.DateTime.t) :: {:ok, String.t}
          track: fn jti, expiry ->
            Logger.debug(fn -> "Tracker Stub :track jti=#{inspect(jti)} expiry=#{inspect(expiry)}" end)
            # Mimic the "cannot track more than once" behaviour:
            already_tracked? =
              Agent.get(agent, fn list -> list |> Enum.find(fn {key, _} -> key == jti end) end) !=
                nil

            if already_tracked? do
              {:error, :already_tracked}
            else
              Agent.update(agent, fn list -> [{jti, %{expiry: expiry}} | list] end)
              {:ok, 'some_phx_ref'}
            end
          end,
          # @callback untrack(jti: String.t) :: :ok
          untrack: fn jti ->
            Logger.debug(fn -> "Tracker Stub :untrack jti=#{inspect(jti)}" end)
            Agent.update(agent, fn list -> list |> Enum.filter(fn {key, _} -> key != jti end) end)
            :ok
          end,
          # @callback list() :: [{String.t, %{optional(String.t) => String.t}}]
          list: fn ->
            Logger.debug("Tracker Stub :list")
            Agent.get(agent, fn list -> list end)
          end,
          # @callback find(jti: String.t) :: {String.t, %{optional(String.t) => String.t}} | nil
          find: fn jti ->
            Logger.debug(fn -> "Tracker Stub :find jti=#{inspect(jti)}" end)
            Agent.get(agent, fn list -> list |> Enum.find(fn {key, _} -> key == jti end) end)
          end
        ],
        behaviour: RigInboundGateway.Blacklist.Tracker.TrackerBehaviour,
        call_info: true
      )

    [tracker: tracker]
  end
end
