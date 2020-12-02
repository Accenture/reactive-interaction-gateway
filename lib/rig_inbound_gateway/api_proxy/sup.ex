defmodule RigInboundGateway.ApiProxy.Sup do
  @moduledoc """
  Supervisor.

  """

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      {RigInboundGateway.ApiProxy.PresenceHandler, [pubsub_server: Rig.PubSub]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
