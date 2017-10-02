defmodule Gateway.ApiProxy.Sup do
  @moduledoc """
  Supervisor.

  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Gateway.ApiProxy.PresenceHandler, _args = [[pubsub_server: Gateway.PubSub]]),
    ]
    supervise(children, strategy: :one_for_one)
  end
end
