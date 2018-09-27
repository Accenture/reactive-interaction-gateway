defmodule RigApi.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      RigApi.Endpoint
    ]

    opts = [strategy: :one_for_one, name: RigApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    RigApi.Endpoint.config_change(changed, removed)
    :ok
  end
end
