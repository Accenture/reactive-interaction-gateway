defmodule Gateway.RateLimit.Common do
  @moduledoc false
  require Logger
  alias Gateway.RateLimit

  def settings, do: %{
    table_name: :rate_limit_buckets,
    enabled?: fetch_env!(:enabled?),
    per_ip?: fetch_env!(:per_ip?),
    avg_rate_per_sec: fetch_env!(:avg_rate_per_sec),
    burst_size: fetch_env!(:burst_size),
    sweep_interval_ms: fetch_env!(:sweep_interval_ms),
    # It's also possible to set the current time, for use in tests:
    # current_unix_time: ...
  }

  def now_unix do
    {megasecs, secs, microsecs} = :os.timestamp()
    megasecs * 1_000_000 + secs + microsecs / 1_000_000
  end

  def ensure_table(table_name) do
    heir_pid = Process.whereis(RateLimit.TableOwner)
    :ets.new table_name, [:set, :public, :named_table, {:heir, heir_pid, :noargs}]
    Logger.debug "Created ETS table #{inspect table_name}"
  rescue
    _ in ArgumentError ->
      # This usually just means that the table already exists
      table_name
  end

  defp fetch_env!(key) do
    Application.fetch_env!(
      :gateway,
      _key = "proxy_rate_limit_#{key}" |> String.to_atom
    )
  end
end
