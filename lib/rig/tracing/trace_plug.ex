defmodule RIG.Tracing.Plug do
  @moduledoc """
  Wrapper Module for Opencensus.Plug.Trace from opencensus_plug
  """
  use Opencensus.Plug.Trace
  alias Plug.Conn
  alias RIG.Tracing

  @spec put_req_header(Plug.Conn.headers(), Tracing.t()) :: Plug.Conn.headers()
  def put_req_header(req_headers, tracecontext) do
    req_headers
    |> Enum.reject(fn {k, _} -> k === "traceparent" end)
    |> Enum.reject(fn {k, _} -> k === "tracestate" end)
    |> Enum.concat(tracecontext)
  end

  @spec put_resp_header(Plug.Conn.t(), Tracing.t()) :: Plug.Conn.t()
  def put_resp_header(conn, tracecontext) do
    Enum.each(tracecontext, fn x ->
      {key, val} = x
      # only put traceparent as tracestate is private and shouldn't be forwarded to the client
      if key == "traceparent" do
        conn |> Conn.put_resp_header(key, val)
      end
    end)

    conn
  end
end
