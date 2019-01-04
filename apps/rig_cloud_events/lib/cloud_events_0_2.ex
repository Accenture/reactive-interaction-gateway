defmodule CloudEvents_0_2 do
  # credo:disable-for-previous-line Credo.Check.Readability.ModuleNames
  @moduledoc """
  CloudEvents v0.2

  CloudEvents is a vendor-neutral specification for defining the format of event data.

  Spec: https://github.com/cloudevents/spec/blob/v0.2/spec.md
  """
  alias CloudEvents.ParserMacros
  require ParserMacros

  @behaviour CloudEventParser

  @type t :: %__MODULE__{
          id: String.t(),
          time: Timex.DateTime.t() | nil,
          type: String.t(),
          source: String.t()
        }

  defstruct id: nil,
            time: nil,
            type: nil,
            source: nil

  # ---

  @impl true
  def parse(%{"specversion" => "0.2"} = event) do
    with {:ok, id} <- id(event),
         {:ok, time} <- time(event),
         {:ok, type} <- type(event),
         {:ok, source} <- source(event) do
      {:ok,
       %__MODULE__{
         id: id,
         time: time,
         type: type,
         source: source
       }}
    else
      {:illegal_field, field, error} -> {:error, :illegal_field, {field, error}}
    end
  end

  # ---

  ParserMacros.nonempty_string("id", "id")

  # ---
  ParserMacros.timestamp("time", "time", required?: false)

  # ---

  ParserMacros.nonempty_string("type", "type")

  # ---

  ParserMacros.nonempty_string("source", "source")
end
