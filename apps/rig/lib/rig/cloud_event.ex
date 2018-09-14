defmodule Rig.CloudEvent do
  @moduledoc """
  CloudEvents v0.1

  CloudEvents is a vendor-neutral specification for defining the format of event data.

  Spec: https://github.com/cloudevents/spec/blob/v0.1/spec.md
  """

  @type t :: %{required(String.t()) => any}

  @cloud_events_version "0.1"
  @template %{
    "cloudEventsVersion" => @cloud_events_version,
    "eventTime" => nil,
    "extensions" => nil,
    "schemaURL" => nil,
    "contentType" => nil,
    "data" => nil
  }

  def valid?(event), do: do_valid?(Map.merge(@template, event))

  defp do_valid?(%{
         "eventType" => event_type,
         "cloudEventsVersion" => cloud_events_version,
         "source" => source,
         "eventID" => event_id,
         "eventTime" => event_time,
         "extensions" => extensions,
         "schemaURL" => schema_url,
         "contentType" => content_type,
         "data" => _data
       })
       when is_binary(event_type) and cloud_events_version == @cloud_events_version and
              is_binary(source) and is_binary(event_id) and
              (is_nil(event_time) or is_binary(event_time)) and
              (is_nil(extensions) or is_map(extensions)) and
              (is_nil(schema_url) or is_binary(schema_url)) and
              (is_nil(content_type) or is_binary(content_type)) do
    true
  end

  defp do_valid?(_), do: false

  def event_type(e), do: Map.fetch!(e, "eventType")
  def cloud_events_version(e), do: Map.fetch!(e, "cloudEventsVersion")
  def source(e), do: Map.fetch!(e, "source")
  def event_id(e), do: Map.fetch!(e, "eventID")
  def event_time(e), do: Map.get(e, "eventTime")
  def extensions(e), do: Map.get(e, "extensions")
  def schema_url(e), do: Map.get(e, "schemaURL")
  def content_type(e), do: Map.get(e, "contentType")
  def data(e), do: Map.get(e, "data")

  @spec new(t) :: {:ok, t} | {:error, :parse_error}
  def new(event) do
    event =
      event
      |> Map.to_list()
      |> Enum.filter(fn {_, v} -> not is_nil(v) end)
      |> Enum.into(%{})
      |> Map.put_new("eventID", UUID.uuid4())
      |> Map.put_new("eventTime", Timex.now() |> Timex.format!("{RFC3339}"))

    if valid?(event), do: {:ok, event}, else: {:error, :parse_error}
  end

  @spec new!(t) :: t
  def new!(event) do
    {:ok, event} = new(event)
    event
  end

  @spec with_data(t(), content_type :: String.t(), data :: binary()) :: t()
  def with_data(event, content_type, data) do
    event
    |> Map.put("contentType", content_type)
    |> Map.put("data", data)
  end

  @spec with_data(t(), data :: any) :: t()
  def with_data(event, data)

  def with_data(event, nil) do
    # If data is nil, we need neither data nor contentType:
    event
    |> Map.delete("contentType")
    |> Map.delete("data")
  end

  def with_data(event, data) do
    # If there is no content-type set, the data is added as-is:
    event
    |> Map.delete("contentType")
    |> Map.put("data", data)
  end
end
