defmodule Rig.EventStream.KinesisToFilter do
  @moduledoc """
  Consumes events and forwards them to the event filter by event type.

  """

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigTracing.TracePlug

  require Logger

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kinesis_handler(message) do
    case CloudEvent.parse(message) do
      {:ok, %CloudEvent{} = cloud_event} ->
        TracePlug.with_child_span_from_cloudevent "kinesis_to_filter", cloud_event do
          cloud_event =
            cloud_event
            |> TracePlug.append_distributed_tracing_context_to_cloudevent(tracecontext_headers())
            # we only want to send traceparent to frontend
            |> TracePlug.remove_tracestate_from_cloudevent()

          Logger.debug(fn -> inspect(cloud_event.parsed) end)
          EventFilter.forward_event(cloud_event)
          :ok
        end

      {:error, :parse_error} ->
        {:error, :non_cloud_events_not_supported, message}
    end
  rescue
    err -> {:error, err, message}
  end
end
