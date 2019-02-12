defmodule RigMetrics.Application do
  @moduledoc """
  This is the main entry point of the RigMetrics application.
  """
  use Application

  @metrics_enabled? Confex.fetch_env!(:rig_metrics, RigMetrics.Application)[:metrics_enabled?]

  # See https://hexdocs.pm/elixir/Supervisor.html
  # for other strategies and supported options
  def start(_type, _args) do
    children = []

    if @metrics_enabled? == true do
      # TODO: setup currently commented out, as metrics are not yet implemented and
      # therefore shouldn't be exposed yet to the endpoint

      # RigMetrics.ControlInstrumenter.setup()
      # RigMetrics.EventhubInstrumenter.setup()
      # RigMetrics.ProxyInstrumenter.setup()

      RigMetrics.MetricsPlugExporter.setup()
    end

    opts = [strategy: :one_for_one, name: RigMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
