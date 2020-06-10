defmodule RIG.Tracing.Plug do
  @moduledoc """
  Wrapper Module for Opencensus.Plug.Trace from opencensus_plug
  """
  use Opencensus.Plug.Trace
  alias RIG.Tracing

  @spec put_context_header(Plug.Conn.headers(), Tracing.t()) :: Plug.Conn.headers()
  def put_context_header(req_headers, tracecontext) do
    req_headers
    |> Enum.reject(fn {k, _} -> k === "traceparent" end)
    |> Enum.reject(fn {k, _} -> k === "tracestate" end)
    |> Enum.concat(tracecontext)
  end
end
