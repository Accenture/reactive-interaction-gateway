defmodule RigMetrics.SubscriptionsMetrics do
  @moduledoc """
  Metrics instrumenter for the Rig Subscriptions (Websocket, Server-Sent Events, Long Polling).
  """
  use Prometheus.Metric

  # To be called at app startup.
  def setup do
    Gauge.declare(
      name: :rig_subscriptions_total,
      help: "Total count of subscriptions (Websocket, Server-Sent Events, Long Polling)."
    )
  end

  @doc "Sets the Prometheus gauge rig_subscriptions_total"
  def set_subscriptions(subscriptions_amount) do
    Gauge.set([name: :rig_subscriptions_total], subscriptions_amount)
  end
end
