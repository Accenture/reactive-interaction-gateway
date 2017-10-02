defmodule Gateway.Application do
  @moduledoc """
  This is the main entry point of the Gateway application.
  """
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec
    children = [
      supervisor(GatewayWeb.Endpoint, _args = []),
      supervisor(GatewayWeb.Presence, []),
      supervisor(Gateway.Blacklist.Sup, _args = []),
      supervisor(Gateway.RateLimit.Sup, _args = []),
      supervisor(Gateway.ApiProxy.Sup, _args = []),
      worker(Gateway.Kafka.SupWrapper, _args = []),
    ]
    opts = [strategy: :one_for_one, name: Gateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GatewayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
