defmodule Rig.EventStream.KafkaToFilter do
  @moduledoc """
  Consumes events and forwards them to the event filter by event type.

  """
  use Rig.KafkaConsumerSetup

  alias Rig.EventFilter
  alias RIG.Tracing
  alias RigCloudEvents.CloudEvent

  require Tracing.CloudEvent

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(message) do
    case CloudEvent.parse(message) do
      {:ok, %CloudEvent{} = cloud_event} ->
        Tracing.CloudEvent.with_child_span "kafka_to_filter", cloud_event do
          cloud_event =
            cloud_event
            |> Tracing.append_context(Tracing.context(), :private)

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
