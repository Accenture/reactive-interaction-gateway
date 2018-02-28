defmodule Rig.Application do
  @moduledoc false

  use Application
  use Rig.Config, []

  def start(_type, _args) do
    alias Supervisor.Spec

    # Override application logging with environment variable
    conf = config()
    Logger.configure [{:level, conf.log_level}]

    Rig.Discovery.start()

    children = [
      Spec.supervisor(Phoenix.PubSub.PG2, [Rig.PubSub, []])
    ]

    opts = [strategy: :one_for_one, name: Rig.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
