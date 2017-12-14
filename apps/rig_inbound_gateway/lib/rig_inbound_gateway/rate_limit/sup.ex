defmodule RigInboundGateway.RateLimit.Sup do
  @moduledoc """
  Supervisor handling Rate-Limit processes.

  In case rate-limiting is disabled (by setting the env config :enabled? to
  false), the supervisor doesn't start the RateLimit.Sweeper (which is
  responsible for periodically cleaning up the configured ETS table).

  On the other hand, the TableOwner process is always started. This is
  convenient for testing (most of the RigInboundGateway.RateLimit module doesn't work
  without it, assuming :enabled? is true) and it doesn't do any harm in a
  production setting.
  """
  use Supervisor
  alias RigInboundGateway.RateLimit

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl Supervisor
  def init(:ok) do
    conf = RateLimit.config()
    specs = [
      {true, worker(RateLimit.TableOwner, _args = [])},
      {conf.enabled?, worker(RateLimit.Sweeper, _args = [])},
    ]
    Supervisor.init(
      _children = (for {true, child} <- specs, do: child),
      strategy: :rest_for_one
    )
  end
end
