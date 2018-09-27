defmodule RigOutboundGateway.Application do
  @moduledoc false

  use Application

  alias RigOutboundGateway.Kinesis
  alias RigOutboundGateway.KinesisFirehose

  def start(_type, _args) do
    children = [
      RigOutboundGateway.Kinesis,
      RigOutboundGateway.KinesisFirehose
    ]

    opts = [strategy: :one_for_one, name: RigOutboundGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
