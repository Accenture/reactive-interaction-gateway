defmodule CloudEvents do
  @moduledoc """
  CloudEvents is a vendor-neutral specification for defining the format of event data.

  See: https://github.com/cloudevents
  """
  @behaviour CloudEventParser

  # ---

  @impl true
  def parse(event) when is_binary(event) do
    case Jason.decode(event) do
      {:ok, event} -> parse(event)
      {:error, error} -> {:error, :invalid_json, error}
    end
  end

  @impl true
  def parse(event) do
    parser =
      case event do
        %{"specversion" => "0.2"} -> CloudEvents_0_2
        %{"cloudEventsVersion" => "0.1"} -> CloudEvents_0_1
      end

    parser.parse(event)
  end
end
