defmodule Rig.EventStream.KafkaToHttp do
  @moduledoc """
  Forwards all consumed events to an HTTP endpoint.

  """
  use Rig.KafkaConsumerSetup, [:targets]

  alias Rig.CloudEvent

  alias HTTPoison

  # ---

  def validate(%{targets: []}), do: :abort
  def validate(conf), do: {:ok, conf}

  # ---

  def kafka_handler(message) do
    case CloudEvent.new(message) do
      {:ok, cloud_event} ->
        Logger.debug(fn -> inspect(cloud_event) end)
        forward_to_external_endpoint(cloud_event)

      {:error, :parse_error} ->
        {:error, :non_cloud_events_not_supported, message}
    end
  rescue
    err -> {:error, err, message}
  end

  # ---

  defp forward_to_external_endpoint(cloud_event) do
    %{targets: targets} = config()

    for url <- targets do
      case HTTPoison.post(url, cloud_event) do
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
