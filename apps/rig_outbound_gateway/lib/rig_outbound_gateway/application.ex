defmodule RigOutboundGateway.Application do
  @moduledoc false

  use Application

  alias RigOutboundGateway.Kafka
  alias RigOutboundGateway.Kinesis

  def start(_type, _args) do
    children = [
      Kafka.SupWrapper,
      Kinesis.JavaClient
    ]

    opts = [strategy: :one_for_one, name: RigOutboundGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
