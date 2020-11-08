defmodule RigInboundGatewayWeb.ConnectionLimit do
  @moduledoc "Used to enforce a limit on the maximum connections per minute"
  require Logger
  use GenServer

  @default_limit_per_minute 5_000
  @default_ets_table __MODULE__

  #
  # API
  #

  @spec add_connection(opts :: list()) ::
          {:ok, new_count :: integer()} | {:error, :connection_limit_exceeded}
  def add_connection(opts \\ []) do
    limit_per_minute = opts[:limit_per_minute] || @default_limit_per_minute
    table = opts[:ets_table] || @default_ets_table

    # If there table is not there (yet), the limit is not enforced (yet).
    if :ets.whereis(table) == :undefined do
      {:ok, 1}
    else
      new_count =
        :ets.update_counter(
          table,
          :n_connections,
          {_col = 2, _by = 1},
          _default = {:n_connections, 0}
        )

      if new_count > limit_per_minute,
        do: {:error, :connection_limit_exceeded},
        else: {:ok, new_count}
    end
  end

  @spec reset_counter(opts :: list()) :: :ok
  def reset_counter(opts \\ []) do
    table = opts[:ets_table] || @default_ets_table
    :ets.insert(table, {:n_connections, 0})
    :ok
  end

  def start_link(opts \\ []) do
    {ets_table, opts} = Keyword.pop(opts, :ets_table)
    # We create the table here so add_connection works as expected immediately
    :ets.new(ets_table, [:set, :protected, :named_table])
    GenServer.start_link(__MODULE__, %{ets_table: ets_table}, opts)
  end

  #
  # Private
  #

  @impl GenServer
  def init(state) do
    Process.send_after(self(), :reset_counter, _ms = 60_000)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:reset_counter, %{ets_table: ets_table} = state) do
    reset_counter(ets_table)
    Process.send_after(self(), :reset_counter, _ms = 60_000)
    {:noreply, state}
  end
end
