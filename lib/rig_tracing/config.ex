defmodule RigTracing.Config do
  @moduledoc """
  Distributed tracing configuration
  """
  @type tracecontext :: list()

  # {:opencensus, [
  #   {reporters, [{oc_reporter_jaeger, [{hostname, "localhost"},
  #                                      {port, 6831}, %% default for compact protocol
  #                                      {service_name, "service"},
  #                                      {service_tags, #{"key" => "value"}}]}]},
  #   ...]}
end
