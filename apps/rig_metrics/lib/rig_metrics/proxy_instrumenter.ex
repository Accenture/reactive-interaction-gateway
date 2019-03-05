defmodule RigMetrics.ProxyMetrics do
  @moduledoc """
  Metrics instrumenter for the Rig Proxy
  """
  use Prometheus.Metric

  # to be called at app startup.
  def setup() do
    Counter.declare(
      name: :rig_proxy_requests_total,
      help: "Total count of requests through RIG proxy",
      labels: [:method, :path, :target, :status]
    )
  end

  @doc "Increases the Prometheus counter rig_proxy_request_total"
  def count_proxy_request(method, path, target, status) do
    Counter.inc(name: :rig_proxy_requests_total, labels: [method, path, target, status])
  end
end
