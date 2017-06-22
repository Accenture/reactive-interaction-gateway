defmodule Gateway.Blacklist.Sup do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      # The PresenceHandler also starts the Blacklist server. Since that's kind
      # of hard to guess, this supervisor exists to hide this implementation
      # detail to the parent supervisor.
      worker(Gateway.Blacklist.PresenceHandler,
        _args = [[pubsub_server: Gateway.PubSub, store: Gateway.Blacklist.Store]]),
    ]
    supervise(children, strategy: :one_for_one)
  end
end
