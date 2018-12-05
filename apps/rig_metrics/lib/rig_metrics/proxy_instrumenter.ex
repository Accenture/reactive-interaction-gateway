defmodule RigMetrics.ProxyInstrumenter do
  @moduledoc """
  Metrics instrumenter for the Rig Proxy
  """
  use Prometheus.Metric

  # to be called at app startup.
  def setup() do
    Gauge.declare(
      name: :rig_current_session_count,
      help: "Current count of sessions established to RIG"
    )

    Gauge.declare(
      name: :rig_current_subscription_count,
      help: "Current count of subscriptions established to RIG"
    )

    Gauge.declare(
      name: :rig_current_open_proxy_connection_count,
      help: "Current count of open proxy connections established to RIG"
    )

    Counter.declare(
      name: :rig_proxy_requests_total,
      help: "Total count of request through RIG progx"
    )
  end

  def add_session() do
    Gauge.inc(name: :rig_current_session_count)
  end

  def delete_session() do
    Gauge.dec(name: :rig_current_session_count)
  end

  def add_subscription() do
    Gauge.inc(name: :rig_current_subscription_count)
  end

  def delete_subscription() do
    Gauge.dec(name: :rig_current_subscription_count)
  end

  def add_connection() do
    Gauge.inc(name: :rig_current_open_proxy_connection_count)
  end

  def delete_connection() do
    Gauge.dec(name: :rig_current_open_proxy_connection_count)
  end

  def count_proxy_request() do
    Counter.inc(name: :rig_proxy_requests_total)
  end
end
