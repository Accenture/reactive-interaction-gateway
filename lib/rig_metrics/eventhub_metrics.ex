defmodule RigMetrics.EventhubMetrics do
  @moduledoc """
  Metrics instrumenter for the Rig Eventhub
  """
  use Prometheus.Metric

  # to be called at app startup.
  def setup() do
    Counter.declare(
      name: :rig_events_total,
      help: "Total count of events",
      labels: [:eventhub, :topic]
    )

    Counter.declare(
      name: :rig_forwarded_events_total,
      help: "Total count of forwarded events",
      labels: [:eventhub, :topic]
    )

    Counter.declare(
      name: :rig_failed_events_total,
      help: "Total count of invalid events",
      labels: [:eventhub, :topic]
    )

    Counter.declare(
      name: :rig_dropped_events_total,
      help: "Total count of invalid events",
      labels: [:eventhub, :topic]
    )

    Histogram.new(
      name: :rig_event_processing_duration_milliseconds,
      labels: [:eventhub, :topic],
      buckets: [100, 250, 500, 750, 1000],
      duration_unit: :milliseconds,
      help: "Event processing execution time"
    )
  end

  def count_event(eventhub, topic) do
    Counter.inc(name: :rig_events_total, labels: [eventhub, topic])
  end

  def count_forwarded_event(eventhub, topic) do
    Counter.inc(name: :rig_forwarded_events_total, labels: [eventhub, topic])
  end

  def count_failed_event(eventhub, topic) do
    Counter.inc(name: :rig_events_total, labels: [eventhub, topic])
    Counter.inc(name: :rig_failed_events_total, labels: [eventhub, topic])
  end

  def count_dropped_event(eventhub, topic) do
    Counter.inc(name: :rig_events_total, labels: [eventhub, topic])
    Counter.inc(name: :rig_dropped_events_total, labels: [eventhub, topic])
  end

  def measure_event_processing(eventhub, topic, time) do
    Histogram.observe(
      [name: :rig_event_processing_duration_milliseconds, labels: [eventhub, topic]],
      time
    )
  end
end
