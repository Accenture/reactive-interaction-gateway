defmodule RigMetrics.ControlInstrumenter do
  @moduledoc """
  Metrics instrumenter for the Rig Control
  """
  use Prometheus.Metric

  # TODO: setup currently commented out, as metrics are not yet implemented and
  # therefore shouldn't be exposed yet to the endpoint

  # to be called at app startup.
  # def setup() do
  #   Gauge.declare(
  #     name: :rig_sessions_blacklisted,
  #     help: "Current count of sessions blacklisted"
  #   )

  #   Gauge.declare(
  #     name: :rig_routes_configured,
  #     help: "Current count of routes configured for RIG"
  #   )
  # end

  def add_blacklisted_session(increasedBy \\ 1) do
    Gauge.inc([name: :rig_sessions_blacklisted], increasedBy)
  end

  def delete_blacklisted_session(decreasedBy \\ 1) do
    Gauge.dec([name: :rig_sessions_blacklisted], decreasedBy)
  end

  def add_route(increasedBy \\ 1) do
    Gauge.inc([name: :rig_routes_configured], increasedBy)
  end

  def delete_route(decreasedBy \\ 1) do
    Gauge.dec([name: :rig_routes_configured], decreasedBy)
  end
end
