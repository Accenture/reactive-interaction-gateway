defmodule RigMetrics.SubscriptionsMetrics do
  @moduledoc """
  Metrics instrumenter for the Rig Subscriptions (Websocket, Server-Sent Events, Long Polling).
  """
  use Prometheus.Metric

  @gauge name: :rig_subscriptions_total,
         help: "Total count of subscriptions (Websocket, Server-Sent Events, Long Polling)."

  # ---

  @doc "Increases the Prometheus gauge rig_subscriptions_total"
  def add_item(increasedBy \\ 1) do
    Gauge.inc([name: :rig_subscriptions_total], increasedBy)
  end

  @doc "Decreases the Prometheus gauge rig_subscriptions_total"
  def delete_item(decreasedBy \\ 1) do
    Gauge.dec([name: :rig_subscriptions_total], decreasedBy)
  end
end
