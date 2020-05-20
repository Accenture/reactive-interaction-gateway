defmodule RigTracing.TracePlug do
  @moduledoc """
  Wrapper Module for Opencensus.Plug.Trace from opencensus_plug
  """
  use Opencensus.Plug.Trace
  alias RigTracing.Context

  @spec put_tracecontext_header(Plug.Conn.headers(), Context.t()) :: Plug.Conn.headers()
  def put_tracecontext_header(req_headers, tracecontext) do
    req_headers
    |> Enum.reject(fn {k, _} -> k === "traceparent" end)
    |> Enum.reject(fn {k, _} -> k === "tracestate" end)
    |> Enum.concat(tracecontext)
  end
end
