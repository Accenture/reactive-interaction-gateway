defmodule RigInboundGateway.Application do
  @moduledoc """
  This is the main entry point of the RigInboundGateway application.
  """
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(RigInboundGatewayWeb.Endpoint, _args = []),
      supervisor(RigInboundGatewayWeb.Presence, []),
      supervisor(RigInboundGateway.Blacklist.Sup, _args = []),
      supervisor(RigInboundGateway.RateLimit.Sup, _args = []),
      supervisor(RigInboundGateway.ApiProxy.Sup, _args = [])
    ]

    opts = [strategy: :one_for_one, name: RigInboundGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    RigInboundGatewayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
