defmodule Rig.EventStream.KafkaToFilter do
  @moduledoc """
  Consumes events and forwards them to the event filter by event type.

  """
  use Rig.KafkaConsumerSetup

  alias Rig.EventFilter
  alias RIG.Tracing

  require Tracing.CloudEvent

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(body, headers) do
    case Cloudevents.from_kafka_message(body, headers) do
      {:ok, cloud_event} ->
        Tracing.CloudEvent.with_child_span_temp "kafka_to_filter", cloud_event do
          cloud_event =
            cloud_event
            |> Tracing.append_context_with_mode(Tracing.context(), :private)

          Logger.debug(fn -> inspect(cloud_event) end)
          EventFilter.forward_event(cloud_event)
          :ok
        end

      {:error, reason} ->
        {:error, {:non_cloud_events_not_supported, reason, body}}
    end
  rescue
    err -> {:error, {:failed_to_parse_kafka_message, headers, body, err}}
  end
end

# ---
