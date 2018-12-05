defmodule RigMetrics.ControlInstrumenter do
  @moduledoc """
  Metrics instrumenter for the Rig Control
  """
  use Prometheus.Metric

  # to be called at app startup.
  def setup() do
    Gauge.declare(
      name: :rig_sessions_blacklisted,
      help: "Current count of sessions blacklisted"
    )

    Gauge.declare(
      name: :rig_routes_configured,
      help: "Current count of routes configured for RIG"
    )
  end

  def add_blacklisted_session() do
    Gauge.inc(name: :rig_sessions_blacklisted)
  end

  def delete_blacklisted_session() do
    Gauge.dec(name: :rig_sessions_blacklisted)
  end

  def add_route() do
    Gauge.inc(name: :rig_routes_configured)
  end

  def delete_route() do
    Gauge.dec(name: :rig_routes_configured)
  end
end
