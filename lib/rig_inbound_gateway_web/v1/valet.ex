defmodule RigInboundGatewayWeb.V1.Valet do
  @moduledoc """
  """
  require Logger

  use GenServer

  def start_link(name, opts \\ []) do
    state = %{
      name: name,
      opts: opts,
      max_connections_per_minute: 5_000,
      current_connections: 0,
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
    if GenServer.call(pid, :reached_max_connections) do
      Logger.error(fn -> "Valet reached maximum number of connections per minute: XYZ" end)
      {:error, :reached_max_connections}
    else
      GenServer.call(pid, :add_new_connection)
      :ok
    end
  end

  # callbacks

  @impl GenServer
  def init(state) do
    Logger.info(fn -> "Valet server initialized" end)
    {:ok, state}
  end

  @impl GenServer
  def handle_call(
        :reached_max_connections,
        _from,
        %{
          max_connections_per_minute: max_connections_per_minute,
          current_connections: current_connections
        } = state
      ) do
    {:reply, current_connections >= max_connections_per_minute, state}
  end

  @impl GenServer
  def handle_call(
        :add_new_connection,
        _from,
        %{current_connections: current_connections, cleanup_started: cleanup_started} = state
      ) do
    # start cleanup after the first connection
    if !cleanup_started do
      Process.send_after(self(), :reset, 60 * 1_000)
      Logger.info(fn -> "Valet scheduled cleanup of maximum connections per minute" end)
    end

    {:reply, :ok, %{state | current_connections: current_connections + 1, cleanup_started: true}}
  end

  @impl GenServer
  def handle_info(:reset, state) do
    Logger.debug(fn ->
      "Valet is resetting current connections, next reset in 60 seconds"
    end)

    Process.send_after(self(), :reset, 60 * 1_000)
    {:noreply, %{state | current_connections: 0}}
  end
end
