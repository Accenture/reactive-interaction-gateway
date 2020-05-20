defmodule Rig.EventStream.KafkaToFilter do
  @moduledoc """
  Consumes events and forwards them to the event filter by event type.

  """
  use Rig.KafkaConsumerSetup

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent
  alias RigTracing.CloudEvent, as: TraceCloudEvent
  alias RigTracing.Context

  require TraceCloudEvent

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(message) do
    case CloudEvent.parse(message) do
      {:ok, %CloudEvent{} = cloud_event} ->
        TraceCloudEvent.with_child_span "kafka_to_filter", cloud_event do
          cloud_event =
            cloud_event
            |> Context.append_tracecontext(Context.tracecontext(), :private)

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
