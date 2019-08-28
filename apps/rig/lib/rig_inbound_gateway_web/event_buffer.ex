defmodule RigInboundGatewayWeb.EventBuffer do
  @moduledoc """
  A circular buffer for events.

  Buffers events up to a configurable capacity. After that, every new item overwrites
  the oldest one.
  """

  use TypedStruct

  alias RigCloudEvents.CloudEvent

  @typedoc "A circular event buffer."
  typedstruct do
    field(:capacity, pos_integer(), enforce: true)
    field(:events, [CloudEvent.t()], default: [])
  end

  @doc "Creates a new EventBuffer with the given capacity."
  @spec new(pos_integer()) :: __MODULE__.t()
  def new(capacity), do: %__MODULE__{capacity: capacity}

  @doc "The capacity is the maximum number of events this buffer can hold."
  @spec capacity(__MODULE__.t()) :: pos_integer()
  def capacity(%{capacity: capacity}), do: capacity

  @doc "All events, sorted from oldest to newest event."
  @spec all_events(__MODULE__.t()) :: [CloudEvent.t()]
  def all_events(%{events: events}), do: Enum.reverse(events)

  @doc """
  Add an event to this buffer.

  If the buffer runs at full capacity, this overwrites the oldest event in the buffer.
  """
  @spec add_event(__MODULE__.t(), CloudEvent.t()) :: __MODULE__.t()
  def add_event(%{capacity: capacity, events: events} = event_buffer, event) do
    events = [event | events] |> Enum.take(capacity)
    %__MODULE__{event_buffer | events: events}
  end

  @spec events_since(__MODULE__.t(), event_id :: String.t()) ::
          {:ok, [events: [CloudEvent.t()], last_event_id: String.t()]}
          | {:no_such_event, [not_found_id: String.t(), last_event_id: String.t()]}
  def events_since(%{capacity: capacity, events: events}, event_id) do
    last_event_id = events |> hd() |> CloudEvent.id!()
    newer_events = Enum.take_while(events, fn event -> CloudEvent.id!(event) != event_id end)

    if length(newer_events) == capacity do
      {:no_such_event, [not_found_id: event_id, last_event_id: last_event_id]}
    else
      newer_events_asc = Enum.reverse(newer_events)
      {:ok, [events: newer_events_asc, last_event_id: last_event_id]}
    end
  end
end
