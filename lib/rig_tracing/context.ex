defmodule RigTracing.Context do
  @moduledoc """
  Distributed Tracing Context instrumenter
  """

  alias RigCloudEvents.CloudEvent
  alias RigTracing.Config

  require Logger

  @spec tracecontext() :: list
  def tracecontext do
    for {k, v} <- :oc_propagation_http_tracecontext.to_headers(:ocp.current_span_ctx()) do
      {k, List.to_string(v)}
    end
  end

  # ---

  def append_tracecontext(a, b, mode \\ :public)

  @spec append_tracecontext(CloudEvent.t(), Config.tracecontext(), mode :: atom()) ::
          CloudEvent.t()
  def append_tracecontext(%CloudEvent{} = cloudevent, tracecontext, mode) do
    cloudevent =
      cloudevent.json
      |> Jason.decode!()
      |> append_tracecontext(tracecontext)
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

  @spec append_tracecontext(map, Config.tracecontext()) :: map
  def append_tracecontext(%{} = map, tracecontext, _mode) do
    Enum.reduce(tracecontext, map, fn trace_header, acc ->
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
