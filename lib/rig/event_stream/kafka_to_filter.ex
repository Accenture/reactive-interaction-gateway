defmodule Rig.EventStream.KafkaToFilter do
  @moduledoc """
  Consumes events and forwards them to the event filter by event type.

  """
  use Rig.KafkaConsumerSetup

  import RigTracing.TracePlug

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(message) do
    case CloudEvent.parse(message) do
      {:ok, %CloudEvent{} = cloud_event} ->
        with_child_span_from_cloudevent("kafka_to_filter", cloud_event) do
          cloud_event =
            cloud_event
            |> append_distributed_tracing_context_to_cloudevent(tracecontext_headers())

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

# ---
