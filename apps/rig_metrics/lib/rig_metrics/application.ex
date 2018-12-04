defmodule RigMetrics.Application do
  @moduledoc """
  This is the main entry point of the RigMetrics application.
  """
  use Application

  # See https://hexdocs.pm/elixir/Supervisor.html
  # for other strategies and supported options
  def start(_type, _args) do
    children = []

    RigMetrics.MetricsPlugExporter.setup()

    opts = [strategy: :one_for_one, name: RigMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
