defmodule Gateway.Application do
  @moduledoc """
  This is the main entry point of the Gateway application.
  """
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    app_env =
      :gateway
      |> Application.get_env(GatewayWeb.Endpoint)
      |> Keyword.get(:env)

    # Define workers and child supervisors to be supervised
    maybe_kafka_worker =
      if app_env == :test do
        []
      else
        [worker(Gateway.Kafka.SupWrapper, _args = [])]
      end
    children = [
      supervisor(GatewayWeb.Endpoint, _args = []),
      supervisor(GatewayWeb.Presence, []),
      supervisor(Gateway.Blacklist.Sup, _args = []),
    ] ++ maybe_kafka_worker

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
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
