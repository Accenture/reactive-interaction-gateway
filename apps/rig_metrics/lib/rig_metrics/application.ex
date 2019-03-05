defmodule RigMetrics.Application do
  @moduledoc """
  This is the main entry point of the RigMetrics application.
  """
  use Application

  # See https://hexdocs.pm/elixir/Supervisor.html
  # for other strategies and supported options
  def start(_type, _args) do
    children = []

    # TODO: setup currently commented out, as metrics are not yet implemented and
    # therefore shouldn't be exposed yet to the endpoint

    # RigMetrics.ControlInstrumenter.setup()
    # RigMetrics.EventhubInstrumenter.setup()
    RigMetrics.ProxyMetrics.setup()

    RigMetrics.MetricsPlugExporter.setup()

    opts = [strategy: :one_for_one, name: RigMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
