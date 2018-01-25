defmodule RigInboundGateway.RateLimit.TableOwner do
  @moduledoc """
  Keeps the ETS table alive.

  An ETS table always links to a process lifecycle. This process stays alive
  so the table doesn't go away.
  """
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl GenServer
  def init(:ok) do
    {:ok, :nostate}
  end

  @impl GenServer
  def handle_info({:"ETS-TRANSFER", table_name, _from_pid, _args}, state) do
    Logger.debug(fn -> "Accepting transfer of ETS table #{inspect table_name}" end)
    {:noreply, state}
  end
end
