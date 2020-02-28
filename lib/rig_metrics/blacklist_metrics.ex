defmodule RigMetrics.BlacklistMetrics do
  @moduledoc """
  Metrics Metrics for the Rig Blacklist
  """
  use Prometheus.Metric

  # to be called at app startup.
  def setup() do
    Gauge.declare(
      name: :rig_sessions_blacklisted_total,
      help: "Total count of blacklisted sessions"
    )

    Gauge.declare(
      name: :rig_sessions_blacklisted_current,
      help: "Current count of blacklisted sessions"
    )
  end

  def add_blacklisted_session(increasedBy \\ 1) do
    Gauge.inc([name: :rig_sessions_blacklisted_total], increasedBy)
    Gauge.inc([name: :rig_sessions_blacklisted_current], increasedBy)
  end

  def delete_blacklisted_session(decreasedBy \\ 1) do
    Gauge.dec([name: :rig_sessions_blacklisted_current], decreasedBy)
  end
end
