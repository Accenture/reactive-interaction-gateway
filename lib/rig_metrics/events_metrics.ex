defmodule RigMetrics.EventsMetrics do
  @moduledoc """
  Metrics instrumenter for the Rig Events
  """
  use Prometheus.Metric

  # to be called at app startup.
  def setup() do
    # consumer

    Counter.declare(
      name: :rig_events_total,
      help: "Total count of events",
      labels: [:source, :topic]
    )

    Counter.declare(
      name: :rig_forwarded_events_total,
      help: "Total count of forwarded events",
      labels: [:source, :topic]
    )

    Counter.declare(
      name: :rig_failed_events_total,
      help: "Total count of failed events",
      labels: [:source, :topic]
    )

    Counter.declare(
      name: :rig_dropped_events_total,
      help: "Total count of dropped events",
      labels: [:source, :topic]
    )

    Histogram.new(
      name: :rig_event_processing_duration_milliseconds,
      labels: [:source, :topic],
      buckets: [1, 2, 5, 10, 25, 50, 75, 100, 250, 500, 750, 1000],
      help: "Event processing execution time in milliseconds"
    )

    # producer

    Counter.declare(
      name: :rig_produced_events_total,
      help: "Total count of produced events",
      labels: [:target, :topic]
    )

    Counter.declare(
      name: :rig_failed_produce_events_total,
      help: "Total count of events failed to produce",
      labels: [:target, :topic]
    )
  end

  # consumer

  @doc "Increases the Prometheus counter rig_forwarded_events_total"
  def count_forwarded_event(source, topic) do
    Counter.inc(name: :rig_forwarded_events_total, labels: [source, topic])
  end

  @doc "Increases the Prometheus counters rig_events_total, rig_failed_events_total"
  def count_failed_event(source, topic) do
    Counter.inc(name: :rig_events_total, labels: [source, topic])
    Counter.inc(name: :rig_failed_events_total, labels: [source, topic])
  end

  @doc "Increases the Prometheus counters rig_events_total, rig_dropped_events_total"
  def count_dropped_event(source, topic) do
    Counter.inc(name: :rig_events_total, labels: [source, topic])
    Counter.inc(name: :rig_dropped_events_total, labels: [source, topic])
  end

  @doc "Increases the Prometheus counters rig_events_total and observes histogram rig_event_processing_duration_milliseconds"
  def measure_event_processing(source, topic, time) do
    Counter.inc(name: :rig_events_total, labels: [source, topic])

    Histogram.observe(
      [name: :rig_event_processing_duration_milliseconds, labels: [source, topic]],
      time
    )
  end

  # producer

  @doc "Increases the Prometheus counter rig_produced_events_total"
  def count_produced_event(target, topic) do
    Counter.inc(name: :rig_produced_events_total, labels: [target, topic])
  end

  @doc "Increases the Prometheus counter rig_failed_produce_events_total"
  def count_failed_produce_event(target, topic) do
    Counter.inc(name: :rig_failed_produce_events_total, labels: [target, topic])
  end
end
