defmodule RigMetrics.Telemetry do
  @moduledoc """
  Telemtry instrumentation for Phoenix LiveDashboard
  """
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {:telemetry_poller, period: 10_000},
      {TelemetryMetricsPrometheus, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # proxy
      proxy_counter_metric([]),
      proxy_counter_metric([:target]),
      proxy_counter_metric([:path]),
      proxy_counter_metric([:response_from]),
      proxy_counter_metric([:status]),
      proxy_counter_metric([:method]),
      # events
      events_counter_metric("Forwarded events", [:events, :count_forwarded], [:type]),
      events_counter_metric("Consumed events", [:events, :count_consumed], [:source, :topic]),
      events_counter_metric("Events failed to consume", [:events, :count_consume_failed], [
        :source,
        :topic
      ]),
      events_counter_metric("Produced events", [:events, :count_produced], [:target, :topic]),
      events_counter_metric("Events failed to produce", [:events, :count_produce_failed], [
        :target,
        :topic
      ])
    ]
  end

  defp proxy_counter_metric(tags),
    do:
      counter("Proxy requests",
        event_name: [:proxy, :count],
        tags: tags,
        reporter_options: [
          nav: "Proxy"
        ]
      )

  defp events_counter_metric(title, events, tags),
    do:
      counter(title,
        event_name: events,
        tags: tags,
        reporter_options: [
          nav: "Events"
        ]
      )
end
