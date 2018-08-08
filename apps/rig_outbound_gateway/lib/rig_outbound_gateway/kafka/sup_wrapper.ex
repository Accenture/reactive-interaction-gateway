defmodule RigOutboundGateway.Kafka.SupWrapper do
  @moduledoc """
  Prevents the Kafka subsystem to crash the node on startup.

  Normally, restarts due to connection loss are taken care off by `Rig.Kafka.Sup`.
  In case no Kafka broker is available at startup, `Rig.Kafka.Sup` fails to start,
  bringing down the application. This might not be desirable, as the Rig might be
  started before Kafka comes up. In case a disaster happens, this makes booting up the
  overall system easier.

  We trap only `:failed_to_start_child` here; all other errors will crash this server,
  and thus propagate up.

  Also note that in case `:kafka_enabled?` is `false` in the env config, the GenServer
  doesn't start anything.
  """
  use Rig.Config, [:enabled?, :restart_delay_ms]
  use GenServer
  require Logger

  alias RigOutboundGateway.Kafka.Sup, as: KafkaSupervisor

  ## Client API

  def start_link(opts) do
    conf = config()
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, _args = conf.enabled?, opts)
  end

  ## Server callbacks

  @impl GenServer
  def init(false = _kafka_enabled?) do
    :ignore
  end
  def init(true = _kafka_enabled?) do
    Process.flag :trap_exit, true
    send(self(), :start_sup)
    {:ok, %{n_attempts: 0}}
  end

  @impl GenServer
  def handle_info(:start_sup, old_state) do
    Logger.debug(fn -> "Starting Kafka supervisor (attempt #{next_attempt_no(old_state)})" end)
    new_state = case KafkaSupervisor.start_link() do
      {:ok, _} ->
        Map.put old_state, :n_attempts, 0
      _ ->
        Map.update! old_state, :n_attempts, &(&1 + 1)
    end
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(
    {:EXIT,
      _pid,
      {:shutdown,
        {:failed_to_start_child, module, {err, _info}}
      }
    },
    old_state
  ) do
    %{restart_delay_ms: restart_delay_ms} = config()
    Logger.warn("""
    Supervisor startup failed (attempt #{cur_attempt_no(old_state)}, #{inspect module}): #{inspect err}
    Attempt #{next_attempt_no(old_state)} commences in #{restart_delay_ms / 1000} seconds..
    """)
    :timer.sleep restart_delay_ms
    send(self(), :start_sup)
    {:noreply, old_state}
  end

  ## Private

  defp cur_attempt_no(state) do
    "\##{Map.get(state, :n_attempts)}"
  end

  defp next_attempt_no(state) do
    "\##{Map.get(state, :n_attempts) + 1}"
  end
end
