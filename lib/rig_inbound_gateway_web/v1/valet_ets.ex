defmodule RigInboundGatewayWeb.V1.ValetETS do
  @moduledoc """
  """
  require Logger

  use GenServer

  def start_link(name, opts \\ []) do
    state = %{
      name: name,
      opts: opts,
      ets_table: nil,
      max_connections_per_minute: 5_000,
      cleanup_started: false
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @spec add_new_connection(pid | atom) :: :ok

  def add_new_connection(name) when is_atom(name) do
    pid = Process.whereis(name)
    add_new_connection(pid)
  end

  def add_new_connection(pid) do
    {reached_max_connections?, current_connections} =
      GenServer.call(pid, :reached_max_connections)

    if reached_max_connections? do
      Logger.error(fn -> "Valet reached maximum number of connections per minute: XYZ" end)
      {:error, :reached_max_connections}
    else
      GenServer.call(pid, {:add_new_connection, current_connections})
      :ok
    end
  end

  # callbacks

  @impl GenServer
  def init(%{opts: opts} = state) do
    ets_table = opts[:ets_table] || ets_table_name(self())
    :ets.new(ets_table, [:set, :protected, :named_table, {:read_concurrency, true}])
    ets_table |> save({:current_connections, 0})

    Logger.info(fn -> "Valet server initialized #{inspect(ets_table)}" end)
    {:ok, %{state | ets_table: ets_table}}
  end

  @impl GenServer
  def handle_call(
        :reached_max_connections,
        _from,
        %{ets_table: ets_table, max_connections_per_minute: max_connections_per_minute} = state
      ) do
    [[current_connections]] = :ets.match(ets_table, {:current_connections, :"$1"})

    {:reply, {current_connections >= max_connections_per_minute, current_connections}, state}
  end

  @impl GenServer
  def handle_call(
        {:add_new_connection, current_connections},
        _from,
        %{cleanup_started: cleanup_started, ets_table: ets_table} = state
      ) do
    # start cleanup after the first connection
    if !cleanup_started do
      Process.send_after(self(), :reset, 60 * 1_000)
      Logger.info(fn -> "Valet scheduled cleanup of maximum connections per minute" end)
    end

    ets_table
    |> save({:current_connections, current_connections + 1})

    {:reply, :ok, %{state | cleanup_started: true}}
  end

  @impl GenServer
  def handle_info(:reset, %{ets_table: ets_table} = state) do
    Logger.debug(fn ->
      "Valet is resetting current connections, next reset in 60 seconds"
    end)

    ets_table |> save({:current_connections, 0})

    Process.send_after(self(), :reset, 60 * 1_000)
    {:noreply, state}
  end

  defp save(ets_table, record) do
    true = :ets.insert(ets_table, record)
    # Logger.debug(fn -> "Added record: #{inspect(record)}" end)
    record
  end

  defp ets_table_name(pid),
    do: "valet_#{:erlang.pid_to_list(pid)}" |> String.to_atom()
end
