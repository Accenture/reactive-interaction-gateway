defmodule RigMetrics.ProxyMetrics do
  @moduledoc """
  Metrics instrumenter for the Rig Proxy
  """
  use Prometheus.Metric

  @counter name: :rig_proxy_requests_total,
           help: "Total count of requests through RIG proxy",
           labels: [:method, :path, :target, :response_from, :status]

  # to be called at app startup.
  def setup do
    events = [
      [:proxy, :count],
      [:proxy, :get]
    ]

    # Attach defined events to a telemetry callback
    :telemetry.attach_many("proxy-metrics", events, &__MODULE__.handle_event/4, nil)
  end

  # ---

  @doc "Increases the Prometheus counter rig_proxy_request_total"
  def count_proxy_request(method, path, target, response_from, status) do
    :telemetry.execute(
      [:proxy, :count],
      %{},
      %{method: method, path: path, target: target, response_from: response_from, status: status}
    )

    Counter.inc(
      name: :rig_proxy_requests_total,
      labels: [method, path, target, response_from, status]
    )
  end

  @doc "Gets current value of metric rig_proxy_request_total"
  def get_current_value(method, path, target, response_from, status) do
    :telemetry.execute(
      [:proxy, :get],
      %{},
      %{method: method, path: path, target: target, response_from: response_from, status: status}
    )

    Counter.value(
      name: :rig_proxy_requests_total,
      labels: [method, path, target, response_from, status]
    )
  end
end
