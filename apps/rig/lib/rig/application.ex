defmodule Rig.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    alias Supervisor.Spec

    children = [
      Spec.supervisor(Phoenix.PubSub.PG2, [Rig.PubSub, []])
    ]

    opts = [strategy: :one_for_one, name: Rig.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
