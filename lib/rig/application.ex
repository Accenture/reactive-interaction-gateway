defmodule Rig.Application do
  @moduledoc """
  This is the main entry point of the Rig application.
  """
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    Rig.Discovery.start()

    children = [
      supervisor(RigWeb.Endpoint, _args = []),
      supervisor(RigWeb.Presence, []),
      supervisor(Rig.Blacklist.Sup, _args = []),
      supervisor(Rig.RateLimit.Sup, _args = []),
      supervisor(Rig.ApiProxy.Sup, _args = []),
      worker(Rig.Kafka.SupWrapper, _args = []),
    ]
    opts = [strategy: :one_for_one, name: Rig.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RigWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
