defmodule RigMetrics.EventhubInstrumenter do
  @moduledoc """
  Metrics instrumenter for the Rig Eventuhub
  """
  use Prometheus.Metric

  # TODO: setup currently commented out, as metrics are not yet implemented and therefore shouldn't be exposed yet to the endpoint

  # to be called at app startup.
  # def setup() do
  #   Counter.declare(
  #     name: :rig_processed_events_total,
  #     help: "Total count of processed events",
  #     labels: [:node]
  #   )

  #   Counter.declare(
  #     name: :rig_forwarded_events_total,
  #     help: "Total count of forwarded events",
  #     labels: [:node]
  #   )

  #   Counter.declare(
  #     name: :rig_dropped_events_total,
  #     help: "Total count of dropped events",
  #     labels: [:node]
  #   )
  # end

  def count_forwarded_event(node) do
    Counter.inc(name: :rig_processed_events_total, labels: [node])
    Counter.inc(name: :rig_forwarded_events_total, labels: [node])
  end

  def count_dropped_event(node) do
    Counter.inc(name: :rig_processed_events_total, labels: [node])
    Counter.inc(name: :rig_dropped_events_total, labels: [node])
  end
end
