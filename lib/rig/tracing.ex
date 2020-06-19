defmodule RIG.Tracing do
  @moduledoc """
  Module that handle trace-context according to W3C.

  Accepts and forwards trace-context both from/to http endpoints and from/to event-based systems
  using cloudevents
  """
  use Rig.Config, [
    :jaeger_host,
    :jaeger_port,
    :jaeger_service_name,
    :zipkin_address,
    :zipkin_service_name
  ]

  alias RigCloudEvents.CloudEvent

  require Logger

  @type t :: list()

  def start do
    conf = config()
    Application.put_env(:opencensus, :reporters, reporters(conf, "jaeger"), [:persistent])
    Application.put_env(:opencensus, :reporters, reporters(conf, "zipkin"), [:persistent])
    Application.ensure_all_started(:opencensus, :permanent)
  end

  # ---

  defp reporters(%{jaeger_host: ''}, "jaeger"), do: []
  defp reporters(%{zipkin_address: ''}, "zipkin"), do: []

  defp reporters(conf, "jaeger"),
    do: [
      {
        :oc_reporter_jaeger,
        [
          {:hostname, conf.jaeger_host},
          {:port, conf.jaeger_port},
          {:service_name, conf.jaeger_service_name}
        ]
      }
    ]

  defp reporters(conf, "zipkin"),
    do: [
      {
        :oc_reporter_zipkin,
        [
          {:address, conf.zipkin_address},
          {:local_endpoint, %{:serviceName => conf.zipkin_service_name}}
        ]
      }
    ]

  # ---

  @spec context :: list
  def context do
    for {k, v} <- :oc_propagation_http_tracecontext.to_headers(:ocp.current_span_ctx()) do
      {k, List.to_string(v)}
    end
  end

  # ---

  def append_context(a, b, mode \\ :public)

  @spec append_context(CloudEvent.t(), t(), mode :: atom()) ::
          CloudEvent.t()
  def append_context(%CloudEvent{} = cloudevent, context, mode) do
    cloudevent =
      cloudevent.json
      |> Jason.decode!()
      |> append_context(context)
      |> CloudEvent.parse!()

    case mode do
      :private ->
        Logger.debug(fn -> "private mode, remove tracestate." end)
        remove_tracestate(cloudevent)

      _ ->
        cloudevent
    end
  end

  # ---

  @spec append_context(map, t()) :: map
  def append_context(%{} = map, context, _mode) do
    Enum.reduce(context, map, fn trace_header, acc ->
      {key, val} = trace_header
      Map.put(acc, key, val)
    end)
  end

  # ---

  @spec remove_tracestate(CloudEvent.t()) :: CloudEvent.t()
  defp remove_tracestate(%CloudEvent{} = cloudevent) do
    cloudevent.json
    |> Jason.decode!()
    |> Map.delete("tracestate")
    |> CloudEvent.parse!()
  end
end
