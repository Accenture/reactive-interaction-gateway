defmodule RigTracing.TracePlug do
  @moduledoc """
  Wrapper Module for Opencensus.Plug.Trace from opencensus_plug
  """
  use Opencensus.Plug.Trace
  alias RigCloudEvents.CloudEvent
  alias RigCloudEvents.Parser.PartialParser

  @doc "Like Opencensus.Trace.with_child_span, but for cloudevents distributed tracing extension defined in https://github.com/cloudevents/spec/blob/master/extensions/distributed-tracing.md"
  defmacro with_child_span_from_cloudevent(label, event, attributes \\ quote(do: %{}), do: block) do
    line = __CALLER__.line
    module = __CALLER__.module
    file = __CALLER__.file
    function = format_function(__CALLER__.function)

    computed_attributes =
      compute_attributes(attributes, %{
        line: line,
        module: module,
        file: file,
        function: function
      })

    quote do
      tracecontext = []

      tracecontext =
        case PartialParser.context_attribute(unquote(event).parsed, "traceparent") do
          {:ok, traceparent} -> Enum.concat(tracecontext, %{"traceparent" => traceparent})
          _ -> tracecontext
        end

      tracecontext =
        case PartialParser.context_attribute(unquote(event).parsed, "tracestate") do
          {:ok, tracestate} -> Enum.concat(tracecontext, %{"tracestate" => tracestate})
          _ -> tracecontext
        end

      parent_span_ctx = :oc_propagation_http_tracecontext.from_headers(tracecontext)

      new_span_ctx =
        :oc_trace.start_span(unquote(label), parent_span_ctx, %{
          :attributes => unquote(computed_attributes)
        })

      :ocp.with_span_ctx(new_span_ctx)

      try do
        unquote(block)
      after
        :oc_trace.finish_span(new_span_ctx)
        :ocp.with_span_ctx(parent_span_ctx)
      end
    end
  end

  defp format_function(nil), do: nil
  defp format_function({name, arity}), do: "#{name}/#{arity}"

  defp compute_attributes(attributes, default_attributes) when is_list(attributes) do
    {atoms, custom_attributes} = Enum.split_with(attributes, &is_atom/1)

    default_attributes = compute_default_attributes(atoms, default_attributes)

    case Enum.split_with(custom_attributes, fn
           ## map ast
           {:%{}, _, _} -> true
           _ -> false
         end) do
      {[ca_map | ca_maps], []} ->
        ## custom attributes are literal maps, merge 'em
        {:%{}, meta, custom_attributes} =
          List.foldl(ca_maps, ca_map, fn {:%{}, _, new_pairs}, {:%{}, meta, old_pairs} ->
            {:%{}, meta,
             :maps.to_list(:maps.merge(:maps.from_list(old_pairs), :maps.from_list(new_pairs)))}
          end)

        {:%{}, meta,
         :maps.to_list(:maps.merge(:maps.from_list(custom_attributes), default_attributes))}

      {_ca_maps, _other_calls} ->
        [f_ca | r_ca] = custom_attributes

        quote do
          unquote(
            List.foldl(r_ca ++ [Macro.escape(default_attributes)], f_ca, fn ca, acc ->
              quote do
                Map.merge(unquote(acc), unquote(ca))
              end
            end)
          )
        end
    end
  end

  defp compute_attributes(attributes, _default_attributes) do
    attributes
  end

  defp compute_default_attributes(atoms, default_attributes) do
    List.foldl(atoms, %{}, fn
      :default, _acc ->
        default_attributes

      atom, acc ->
        Map.put(acc, atom, Map.fetch!(default_attributes, atom))
    end)
  end

  @spec append_distributed_tracing_context_to_cloudevent(CloudEvent.t(), list) :: CloudEvent.t()
  def append_distributed_tracing_context_to_cloudevent(cloudevent, tracecontext_headers) do
    cloudevent =
      cloudevent.json
      |> Jason.decode!()
      |> append_distributed_tracing_context(tracecontext_headers)
      |> CloudEvent.parse!()

    cloudevent
  end

  @spec append_distributed_tracing_context(map, list) :: map
  def append_distributed_tracing_context(cloudevent, tracecontext_headers) do
    cloudevent =
      Enum.reduce(tracecontext_headers, cloudevent, fn trace_header, acc ->
        {key, val} = trace_header
        Map.put(acc, key, val)
      end)

    cloudevent
  end

  @spec tracecontext_headers() :: list
  def tracecontext_headers do
    for {k, v} <- :oc_propagation_http_tracecontext.to_headers(:ocp.current_span_ctx()) do
      {k, List.to_string(v)}
    end
  end
end
