defmodule Rig.EventStream.KinesisToFilter do
  @moduledoc """
  Consumes events and forwards them to the event filter by event type.

  """

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent

  require Logger

  # ---

  def validate(conf), do: {:ok, conf}

  # ---

  def kinesis_handler(message) do
    case CloudEvent.parse(message) do
      {:ok, %CloudEvent{} = cloud_event} ->
        Logger.debug(fn -> inspect(cloud_event.parsed) end)
        EventFilter.forward_event(cloud_event)
        :ok

      {:error, :parse_error} ->
        {:error, :non_cloud_events_not_supported, message}
    end
  rescue
    err -> {:error, err, message}
  end
end
