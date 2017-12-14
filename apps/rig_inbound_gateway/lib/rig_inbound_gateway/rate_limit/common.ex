defmodule RigInboundGateway.RateLimit.Common do
  @moduledoc false
  require Logger
  alias RigInboundGateway.RateLimit

  def now_unix do
    {megasecs, secs, microsecs} = :os.timestamp()
    megasecs * 1_000_000 + secs + microsecs / 1_000_000
  end

  def ensure_table(table_name) do
    heir_pid = Process.whereis(RateLimit.TableOwner)
    :ets.new(table_name, [:set, :public, :named_table, {:heir, heir_pid, :noargs}])
    Logger.debug(fn -> "Created ETS table #{inspect(table_name)}" end)
    table_name
  rescue
    _ in ArgumentError ->
      # This usually just means that the table already exists
      table_name
  end
end
