defmodule RigInboundGateway.ApiProxy.Sup do
  @moduledoc """
  Supervisor.

  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(RigInboundGateway.ApiProxy.PresenceHandler, _args = [[pubsub_server: RigMesh.PubSub]]),
    ]
    supervise(children, strategy: :one_for_one)
  end
end
