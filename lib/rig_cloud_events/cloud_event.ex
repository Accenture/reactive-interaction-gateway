defmodule RigCloudEvents.CloudEvent do
  @moduledoc """
  CloudEvents is a vendor-neutral specification for defining the format of event data.

  See: https://github.com/cloudevents
  """
  @parser RigCloudEvents.Parser.PartialParser

  @type t :: %__MODULE__{
          json: String.t(),
          parsed: @parser.t()
        }

  defstruct json: nil,
            parsed: nil

  # ---

  @doc """
  Initialize a new CloudEvent given a JSON string.

  The given JSON string is decoded to an object and fields that are relevant for RIG
  are checked for validity. However, note that this function does not implement the
  full specification - a successful pass does not necessarily mean the given JSON
  contains a valid CloudEvent according to the CloudEvents spec.
  """
  @spec parse(String.t()) :: {:ok, t} | {:error, any}
  def parse(json) when is_binary(json) do
    parsed = @parser.parse(json)
    event = %__MODULE__{json: json, parsed: parsed}

    with {:ok, _} <- specversion(event),
         {:ok, _} <- type(event),
         {:ok, _} <- id(event) do
      {:ok, event}
    else
      error -> error
    end
  end

  # Convenience function used in testing.
  #
  # If this would be called in production, of course it would be way more efficient to
  # access the given map directly. However, this modules' raison d'être is the safe
  # handling of incoming JSON encoded data, so it's safe to assume this function is ever
  # only called by tests.
  @spec parse(map) :: {:ok, t} | {:error, any}
  def parse(map) when is_map(map) do
    map |> Jason.encode!() |> parse
  end

  # ---

  @doc """
  Initialize a new CloudEvent or raise.

  See `parse/1`.
  """
  @spec parse!(String.t() | map) :: t
  def parse!(input) do
    case parse(input) do
      {:ok, cloud_event} -> cloud_event
      error -> raise "Failed to parse CloudEvent: #{inspect(error)}"
    end
  end

  # ---

  def specversion(%__MODULE__{parsed: parsed}) do
    cond do
      specversion_0_2?(parsed) -> {:ok, "0.2"}
      specversion_0_1?(parsed) -> {:ok, "0.1"}
      true -> {:error, :not_a_cloud_event}
    end
  end

  def specversion(event) do
    cond do
      specversion_0_2?(event) -> {:ok, "0.2"}
      specversion_0_1?(event) -> {:ok, "0.1"}
      true -> {:error, :not_a_cloud_event}
    end
  end

  # ---

  def specversion!(event) do
    {:ok, value} = specversion(event)
    value
  end

  # ---

  defp specversion_0_1?(parsed) when is_list(parsed) do
    case @parser.context_attribute(parsed, "cloudEventsVersion") do
      {:ok, "0.1"} -> true
      _ -> false
    end
  end

  defp specversion_0_1?(%{cloudEventsVersion: cloudEventsVersion}) do
    case cloudEventsVersion do
      "0.1" -> true
      _ -> false
    end
  end

  defp specversion_0_1?(_event), do: false

  # ---

  defp specversion_0_2?(parsed) when is_list(parsed) do
    case @parser.context_attribute(parsed, "specversion") do
      {:ok, "0.2"} -> true
      _ -> false
    end
  end

  defp specversion_0_2?(%{specversion: specversion}) do
    case specversion do
      "0.2" -> true
      _ -> false
    end
  end

  defp specversion_0_2?(_event), do: false

  # ---

  def type(%__MODULE__{parsed: parsed} = event) do
    case specversion(event) do
      {:ok, "0.2"} -> @parser.context_attribute(parsed, "type")
      {:ok, "0.1"} -> @parser.context_attribute(parsed, "eventType")
    end
  end

  def type(event) do
    case specversion(event) do
      {:ok, "0.2"} -> {:ok, event.type}
      {:ok, "0.1"} -> {:ok, event.eventType}
    end
  end

  # ---

  def type!(event) do
    {:ok, value} = type(event)
    value
  end

  # ---

  def id(%__MODULE__{parsed: parsed} = event) do
    case specversion(event) do
      {:ok, "0.2"} -> @parser.context_attribute(parsed, "id")
      {:ok, "0.1"} -> @parser.context_attribute(parsed, "eventID")
    end
  end

  def id(%{id: id}), do: {:ok, id}

  def id(%{eventID: eventID}), do: {:ok, eventID}

  # ---

  def id!(event) do
    {:ok, value} = id(event)
    value
  end

  # ---

  @spec find_value(t, json_pointer :: String.t()) :: {:ok, value :: any} | {:error, any}
  def find_value(%__MODULE__{parsed: parsed}, json_pointer) do
    @parser.find_value(parsed, json_pointer)
  end

  def find_value(event, json_pointer) do
    parsed =
      event
      |> Cloudevents.to_json()
      |> @parser.parse()

    @parser.find_value(parsed, json_pointer)
  end
end
