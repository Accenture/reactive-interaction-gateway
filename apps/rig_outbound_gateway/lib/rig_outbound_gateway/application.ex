defmodule RigOutboundGateway.Application do
  @moduledoc false

  use Application

  alias RigOutboundGateway.Kafka

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Kafka.Sup, [])
    ]

    opts = [strategy: :one_for_one, name: RigOutboundGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
