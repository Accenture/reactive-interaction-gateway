defmodule RigAuth.Application do
  @moduledoc """
  This is the main entry point of the RigAuth application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Rig.DistributedSet, _args = [SessionBlacklist, [name: SessionBlacklist]])
    ]

    opts = [strategy: :one_for_one, name: RigAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
