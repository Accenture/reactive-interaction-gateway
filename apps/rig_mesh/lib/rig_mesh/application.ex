defmodule RigMesh.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    alias Supervisor.Spec

    children = [
      Spec.supervisor(Phoenix.PubSub.PG2, [RigMesh.PubSub, []])
      # {Phoenix.PubSub.PG2, [RigMesh.PubSub, []]},
    ]

    opts = [strategy: :one_for_one, name: RigMesh.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
