defmodule RigInboundGatewayWeb.PresenceTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias RigInboundGatewayWeb.Presence

  @max_pids 32_000
  @topic "test"

  @tag timeout: 200_000 # ms
  test "how concurrency affects Presence.track's performance" do
    inputs = %{
      " 2_000 pids" => 2_000,
      " 4_000 pids" => 4_000,
      " 8_000 pids" => 8_000,
      "16_000 pids" => 16_000,
      "32_000 pids" => 32_000
    }

    pids = setup_trackable_processes()

    jobs = %{
      "track one after the other" => &track_many(pids, &1),
      "track all in parallel" => &track_many_async(pids, &1)
    }

    Benchee.run(
      jobs,
      inputs: inputs,
      before_each: fn input ->
        clear_tracking(pids, input)
        input
      end
    )
  end

  defp setup_trackable_processes do
    Enum.map(1..@max_pids, fn _ ->
      {:ok, agent} = Agent.start_link(fn -> nil end)
      agent
    end)
  end

  defp clear_tracking(pids, n_pids) do
    pids
    |> Stream.take(n_pids)
    |> Stream.with_index()
    |> Enum.each(&untrack_single/1)
  end

  defp track_many(pids, n_pids) do
    pids
    |> Stream.take(n_pids)
    |> Stream.with_index()
    |> Enum.each(&track_single/1)
  end

  defp track_many_async(pids, n_pids) do
    tasks =
      pids
      |> Stream.take(n_pids)
      |> Stream.with_index()
      |> Enum.map(&Task.async(fn -> track_single(&1) end))

    tasks
    |> Task.yield_many()
    |> Enum.each(fn {task, result} -> {:ok, _} = result end)
  end

  defp track_single({pid, key}) do
    key = if String.valid?(key), do: key, else: inspect(key)

    meta = %{
      time: 0,
      address: "192.168.0.1",
      device: "desktop",
      browser: "Chrome"
    }

    {:ok, _ref} = Presence.track(pid, @topic, key, meta)
  end

  defp untrack_single({pid, key}) do
    key = if String.valid?(key), do: key, else: inspect(key)
    Presence.untrack(pid, @topic, key)
  end
end
