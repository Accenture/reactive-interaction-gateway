defmodule Rig.CloudEvent do
  @moduledoc """
  CloudEvents v0.1

  CloudEvents is a vendor-neutral specification for defining the format of event data.

  Spec: https://github.com/cloudevents/spec/blob/v0.1/spec.md
  """

  @cloud_events_version "0.1"

  @type t :: %__MODULE__{
          event_type: String.t(),
          cloud_events_version: String.t(),
          source: String.t(),
          event_id: String.t(),
          event_time: nil | String.t(),
          extensions: nil | map(),
          schema_url: nil | String.t(),
          content_type: nil | String.t(),
          data: any()
        }

  @enforce_keys [:event_type, :source, :event_id]
  defstruct event_type: nil,
            cloud_events_version: @cloud_events_version,
            source: nil,
            event_id: nil,
            event_time: nil,
            extensions: nil,
            schema_url: nil,
            content_type: nil,
            data: nil

  defimpl String.Chars do
    def to_string(%Rig.CloudEvent{} = event) do
      age =
        case Timex.parse(event.event_time, "{RFC3339}") do
          {:ok, dt} -> " created " <> Timex.from_now(dt)
          _ -> ""
        end

      "Event type=#{event.event_type} id=#{event.event_id} source=#{event.source}#{age}"
    end
  end

  @spec new(event_type :: String.t(), source :: String.t(), event_id :: String.t()) ::
          %__MODULE__{}
  def new(event_type, source, event_id \\ nil) do
    event_id = if is_nil(event_id), do: UUID.uuid4(), else: event_id

    %__MODULE__{event_id: event_id, event_type: event_type, source: source}
    |> with_current_timestamp()
  end

  @spec with_data(t(), content_type :: String.t(), data :: binary()) :: t()
  def with_data(%__MODULE__{} = event, content_type, data) do
    event
    |> Map.replace!(:content_type, content_type)
    |> Map.replace!(:data, data)
  end

  @spec with_current_timestamp(event :: t()) :: t()
  def with_current_timestamp(%__MODULE__{} = event) do
    Map.replace!(event, :event_time, get_current_timestamp())
  end

  @spec get_current_timestamp() :: String.t()
  def get_current_timestamp do
    Timex.now() |> Timex.format!("{RFC3339}")
  end

  @spec parse(map :: %{required(String.t()) => nil | String.t()}) ::
          {:ok, %__MODULE__{}} | {:error, String.t() | %KeyError{}}
  def parse(%{"cloudEventsVersion" => "0.1"} = input) do
    event = %__MODULE__{
      cloud_events_version: "0.1",
      event_type: Map.fetch!(input, "eventType"),
      event_id: Map.fetch!(input, "eventID"),
      source: Map.fetch!(input, "source"),
      event_time: Map.get_lazy(input, "eventTime", &get_current_timestamp/0),
      extensions: Map.get(input, "extensions"),
      schema_url: Map.get(input, "schemaURL"),
      content_type: Map.get(input, "contentType"),
      data: Map.get(input, "data")
    }

    {:ok, event}
  rescue
    err in KeyError -> {:error, err}
  end

  def parse(_input) do
    reason = "unsupported cloud events version"
    hint = "try cloudEventsVersion=#{@cloud_events_version}"
    {:error, "#{reason} (#{hint})"}
  end

  @spec to_json_map(event :: t()) :: map
  def to_json_map(%__MODULE__{} = event) do
    cloud_events_version = @cloud_events_version
    ^cloud_events_version = event.cloud_events_version

    [
      {"eventType", event.event_type},
      {"cloudEventsVersion", cloud_events_version},
      {"source", event.source},
      {"eventID", event.event_id},
      {"eventTime", event.event_time},
      {"schemaURL", event.schema_url},
      {"contentType", event.content_type},
      {"extensions", event.extensions},
      {"data", event.data}
    ]
    |> Enum.filter(fn {_, v} -> not is_nil(v) end)
    |> Enum.into(%{})
  end

  @spec serialize(event :: t()) :: String.t()
  def serialize(%__MODULE__{} = event) do
    event
    |> to_json_map()
    |> Poison.encode!()
  end
end
