defmodule CloudEvents_0_1 do
  # credo:disable-for-previous-line Credo.Check.Readability.ModuleNames
  @moduledoc """
  CloudEvents v0.1

  CloudEvents is a vendor-neutral specification for defining the format of event data.

  Spec: https://github.com/cloudevents/spec/blob/v0.1/spec.md
  """
  alias CloudEvents.ParserMacros
  require ParserMacros

  @behaviour CloudEventParser

  @type t :: %__MODULE__{
          event_id: String.t(),
          event_time: Timex.DateTime.t() | nil,
          event_type: String.t(),
          source: String.t()
        }

  defstruct event_id: nil,
            event_time: nil,
            event_type: nil,
            source: nil

  # ---

  @impl true
  def parse(%{"cloudEventsVersion" => "0.1"} = event) do
    with {:ok, event_id} <- event_id(event),
         {:ok, event_time} <- event_time(event),
         {:ok, event_type} <- event_type(event),
         {:ok, source} <- source(event) do
      {:ok,
       %__MODULE__{
         event_id: event_id,
         event_time: event_time,
         event_type: event_type,
         source: source
       }}
    else
      {:illegal_field, field, error} -> {:error, :illegal_field, {field, error}}
    end
  end

  # ---

  ParserMacros.nonempty_string("eventID", "event_id")

  # ---
  ParserMacros.timestamp("eventTime", "event_time", required?: false)

  # ---

  ParserMacros.nonempty_string("eventType", "event_type")

  # ---

  ParserMacros.nonempty_string("source", "source")
end
