defmodule RigMetrics.EventsMetrics do
  @moduledoc """
  Metrics instrumenter for the Rig Events (consume, produce).
  """
  use Prometheus.Metric

  # Consumer

  @counter name: :rig_consumed_events_total,
           help: "Total count of consumed events.",
           labels: [:source, :topic]
  @counter name: :rig_consumed_events_forwarded_total,
           help:
             "Total count of consumed events forwarded to any frontend channel (Websocket, Server-Sent Events, Long Polling).",
           labels: [:type]
  @counter name: :rig_consumed_events_failed_total,
           help: "Total count of events failed to be consumed.",
           labels: [:source, :topic]
  @histogram name: :rig_consumed_event_processing_duration_milliseconds,
             labels: [:source, :topic],
             buckets: [1, 2, 5, 10, 25, 50, 75, 100, 250, 500, 750, 1000],
             help: "Event consumer processing execution time in milliseconds."

  # Producer

  @counter name: :rig_produced_events_failed_total,
           help: "Total count of events failed to be produced.",
           labels: [:target, :topic]
  @counter name: :rig_produced_events_total,
           help: "Total count of produced events.",
           labels: [:target, :topic]

  # To be called at app startup.
  def setup do
    events = [
      [:events, :count_forwarded],
      [:events, :count_consumed],
      [:events, :count_consume_failed],
      [:events, :histogram_consumer_time],
      [:events, :count_produced],
      [:events, :count_produce_failed]
    ]

    # Attach defined events to a telemetry callback
    :telemetry.attach_many("events-metrics", events, &__MODULE__.handle_event/4, nil)
  end

  # ---

  @doc "Increases the Prometheus counter rig_consumed_events_forwarded_total"
  def count_forwarded_event(type) do
    :telemetry.execute(
      [:events, :count_forwarded],
      %{},
      %{type: type}
    )

    Counter.inc(name: :rig_consumed_events_forwarded_total, labels: [type])
  end

  @doc "Increases the Prometheus counters rig_consumed_events_total, rig_consumed_events_failed_total"
  def count_failed_event(source, topic) do
    :telemetry.execute(
      [:events, :count_consumed],
      %{},
      %{source: source, topic: topic}
    )

    :telemetry.execute(
      [:events, :count_consume_failed],
      %{},
      %{source: source, topic: topic}
    )

    Counter.inc(name: :rig_consumed_events_total, labels: [source, topic])
    Counter.inc(name: :rig_consumed_events_failed_total, labels: [source, topic])
  end

  @doc "Increases the Prometheus counters rig_consumed_events_total and observes histogram rig_consumed_event_processing_duration_milliseconds"
  def measure_event_processing(source, topic, time) do
    :telemetry.execute(
      [:events, :count_consumed],
      %{},
      %{source: source, topic: topic}
    )

    :telemetry.execute(
      [:events, :histogram_consumer_time],
      %{},
      %{source: source, topic: topic, time: time}
    )

    Counter.inc(name: :rig_consumed_events_total, labels: [source, topic])

    Histogram.observe(
      [name: :rig_consumed_event_processing_duration_milliseconds, labels: [source, topic]],
      time
    )
  end

  @doc "Increases the Prometheus counter rig_produced_events_total"
  def count_produced_event(target, topic) do
    :telemetry.execute(
      [:events, :count_produced],
      %{},
      %{target: target, topic: topic}
    )

    Counter.inc(name: :rig_produced_events_total, labels: [target, topic])
  end

  @doc "Increases the Prometheus counter rig_produced_events_failed_total"
  def count_failed_produce_event(target, topic) do
    :telemetry.execute(
      [:events, :count_produce_failed],
      %{},
      %{target: target, topic: topic}
    )

    Counter.inc(name: :rig_produced_events_failed_total, labels: [target, topic])
  end
end
