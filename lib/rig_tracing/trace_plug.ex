defmodule RigTracing.TracePlug do
  @moduledoc """
  Wrapper Module for Opencensus.Plug.Trace from opencensus_plug
  """
  use Opencensus.Plug.Trace

  def append_distributed_tracing_context(cloudevent, tracecontext_headers) do
    cloudevent =
      Enum.reduce(tracecontext_headers, cloudevent, fn trace_header, acc ->
        {key, val} = trace_header
        Map.put(acc, key, val)
      end)

    cloudevent
  end

  def tracecontext_headers do
    for {k, v} <- :oc_propagation_http_tracecontext.to_headers(:ocp.current_span_ctx()) do
      {k, List.to_string(v)}
    end
  end
end
