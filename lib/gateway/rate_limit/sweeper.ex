defmodule Gateway.RateLimit.Sweeper do
  @moduledoc """
  Periodically cleans up the ETS table.

  By default, the remote IP is considered for rate-limiting, and,
  consequently, used within the ETS table key. This means that without
  cleanup, the table would grow quite large very fast.

  The Sweeper cleans the table by removing all records that own a number of
  tokens equal to the configured burst size. This is okay because
  - removing records is atomic (per record)
  - if no record is found for a given endpoint and ip, it is (re-)created
    with the number of tokens equal to the burst size.

  Can be disabled by setting the sweep interval to 0:

    config :gateway, proxy_rate_limit_sweep_interval_ms: 0

  """
  use GenServer
  import Ex2ms
  import Gateway.RateLimit.Common, only: [settings: 0, now_unix: 0, ensure_table: 1]
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl GenServer
  def init(:ok) do
    opts = settings()
    if opts[:sweep_interval_ms] > 0 do
      Logger.info("Rate-limit table-GC enabled (#{inspect opts})")
      send(self(), :sweep)
    end
    {:ok, _state = opts}
  end

  @impl GenServer
  def handle_info(:sweep, %{sweep_interval_ms: interval_ms} = state) when interval_ms > 0 do
    sweep()
    Process.send_after(self(), :sweep, interval_ms)
    {:noreply, state}
  end

  @spec sweep([atom: any]) :: non_neg_integer()
  def sweep(opts \\ []) do
    n_affected = do_sweep(Enum.into(opts, settings()))
    log_result(n_affected)
    n_affected
  end

  defp do_sweep(%{table_name: tab, avg_rate_per_sec: avg_rate_per_sec,
                  burst_size: burst_size} = opts) do
    ensure_table(tab)
    now = Map.get(opts, :current_unix_time, now_unix())
    sweep_matchspec =
      fun do {_key, n_tokens, last_used}
      when n_tokens + (^now - last_used) * ^avg_rate_per_sec >= ^burst_size
      ->
        true
      end
    # Deletes all records where the matchspec returns true
    # and returns the number of deleted records:
    :ets.select_delete(tab, sweep_matchspec)
  end

  defp log_result(0), do: nil
  defp log_result(1), do: Logger.debug("Rate-limit table-GC: 1 record purged")
  defp log_result(n), do: Logger.debug("Rate-limit table-GC: #{n} records purged")
end
