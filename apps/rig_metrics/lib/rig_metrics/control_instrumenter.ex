defmodule RigMetrics.ControlInstrumenter do
  @moduledoc """
  Metrics instrumenter for the Rig Control
  """
  use Prometheus.Metric

  # to be called at app startup.
  def setup() do
    Gauge.declare(
      name: :rig_current_session_blacklisted_count,
      help: "Current count of sessions blacklisted"
    )

    Gauge.declare(
      name: :rig_current_routes_configured_count,
      help: "Current count of routes configured for RIG"
    )
  end

  def add_blacklisted_session() do
    Gauge.inc(name: :rig_current_session_blacklisted_count)
  end

  def delete_blacklisted_session() do
    Gauge.dec(name: :rig_current_session_blacklisted_count)
  end

  def add_route() do
    Gauge.inc(name: :rig_current_routes_configured_count)
  end

  def delete_route() do
    Gauge.dec(name: :rig_current_routes_configured_count)
  end
end
