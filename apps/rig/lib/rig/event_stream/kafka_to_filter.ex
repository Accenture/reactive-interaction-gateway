defmodule Rig.EventStream.KafkaToFilter do
  @moduledoc """
  Consumes events and forwards them to the event filter by event type.

  """
  use Rig.KafkaConsumerSetup

  alias Rig.CloudEvent
  alias Rig.EventFilter

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(message) do
    case CloudEvent.new(message) do
      {:ok, cloud_event} ->
        Logger.debug(fn -> inspect(cloud_event) end)
        EventFilter.forward_event(cloud_event)
        :ok

      {:error, :parse_error} ->
        {:error, :non_cloud_events_not_supported, message}
    end
  rescue
    err -> {:error, err, message}
  end
end
