defmodule Rig.EventStream.KafkaToHttp do
  @moduledoc """
  Forwards all consumed events to an HTTP endpoint.

  """
  use Rig.KafkaConsumerSetup, [:targets]

  alias HTTPoison

  alias RigCloudEvents.CloudEvent

  # ---

  def validate(%{targets: []}), do: :abort
  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(message) do
    case CloudEvent.parse(message) do
      {:ok, %CloudEvent{} = cloud_event} ->
        Logger.debug(fn -> inspect(cloud_event.parsed) end)
        forward_to_external_endpoint(cloud_event)

      {:error, :parse_error} ->
        {:error, :non_cloud_events_not_supported, message}
    end
  rescue
    err -> {:error, err, message}
  end

  # ---

  defp forward_to_external_endpoint(%CloudEvent{json: json}) do
    %{targets: targets} = config()
    headers = [{"content-type", "application/json"}]

    for url <- targets do
      body = json

      case HTTPoison.post(url, body, headers) do
        {:ok, %HTTPoison.Response{status_code: status}}
        when status >= 200 and status < 300 ->
          :ok

        res ->
          Logger.warn(fn -> "Failed to POST #{inspect(url)}: #{inspect(res)}" end)
      end
    end

    # always :ok, as in fire-and-forget:
    :ok
  end
end
