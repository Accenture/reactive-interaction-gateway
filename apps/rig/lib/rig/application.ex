defmodule Rig.Application do
  @moduledoc false

  use Application
  use Rig.Config, [:log_level]

  def start(_type, _args) do
    alias Supervisor.Spec

    # Override application logging with environment variable
    Logger.configure([{:level, config().log_level}])

    Rig.Discovery.start()

    children = [
      Spec.supervisor(Phoenix.PubSub.PG2, [Rig.PubSub, []]),
      Rig.EventFilter.Sup,
      Rig.EventStream.KafkaToFilter,
      Rig.EventStream.KafkaToHttp
    ]

    opts = [strategy: :one_for_one, name: Rig.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
