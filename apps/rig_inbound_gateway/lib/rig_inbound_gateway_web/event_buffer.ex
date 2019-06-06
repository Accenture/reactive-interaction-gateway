defmodule RigInboundGatewayWeb.EventBuffer do
  @moduledoc """
  Buffers events up to a configurable capacity.

  As soon as the buffer's capacity is reached, newly added items overwrite the oldest ones.
  """
  alias __MODULE__
  alias RigCloudEvents.CloudEvent

  defstruct [:capacity, :events, :write_pointer]

  @doc """
  creates a new EventBuffer with the given capacity
  """
  @spec new(number) :: EventBuffer.t()
  def new(capacity) do
    %EventBuffer{capacity: capacity, events: [], write_pointer: 0}
  end

  @doc """
  provides the capacity of a given EventBuffer
  """
  @spec capacity(EventBuffer.t()) :: number
  def capacity(buffer) do
    buffer.capacity
  end

  @doc """
  provides all events of a given EventBuffer
  """
  @spec all_events(EventBuffer.t()) :: List.t()
  def all_events(buffer) do
    buffer.events
  end

  @doc """
  writes a value to the given EventBuffer, overwrites the oldest value if EventBuffer is full
  """
  @spec add_event(EventBuffer.t(), CloudEvent.t()) :: EventBuffer.t()
  def add_event(
        %{
          write_pointer: write_pointer,
          capacity: capacity,
          events: events
        } = event_buffer,
        event
      ) do
    events = insert_or_update(events, write_pointer, event)
    write_pointer = rem(write_pointer + 1, capacity)

    %EventBuffer{
      event_buffer
      | write_pointer: write_pointer,
        events: events
    }
  end

  @spec events_since(EventBuffer.t(), event_id) ::
          {:ok, [events: events, last_event_id: event_id]}
          | {:no_such_event, [not_found_id: event_id, last_event_id: event_id]}
        when events: list(CloudEvent.t()), event_id: String.t()
  def events_since(
        %{
          capacity: capacity,
          write_pointer: write_pointer,
          events: events
        } = _event_buffer,
        event_id
      ) do
    case Enum.find_index(events, fn x -> CloudEvent.id!(x) == event_id end) do
      nil ->
        next_event = Enum.at(events, 0)
        {:no_such_event, [not_found_id: event_id, last_event_id: CloudEvent.id!(next_event)]}

      event_index ->
        read_pointer = rem(event_index + 1, capacity)
        new_events = get_new_events(events, read_pointer, write_pointer, capacity)

        case new_events do
          [] ->
            {:ok, [events: [], last_event_id: event_id]}

          _ ->
            {:ok, [events: new_events, last_event_id: CloudEvent.id!(Enum.at(new_events, -1))]}
        end
    end
  end

  @spec insert_or_update(List.t(), number, any()) :: List.t()
  defp insert_or_update(list, index, element) do
    if index >= length(list) do
      List.insert_at(list, index, element)
    else
      List.replace_at(list, index, element)
    end
  end

  defp get_new_events(events, read_pointer, write_pointer, _capacity)
       when read_pointer < write_pointer do
    get_between(events, read_pointer, write_pointer)
  end

  defp get_new_events(events, read_pointer, write_pointer, capacity)
       when read_pointer > write_pointer do
    get_between(events, read_pointer, capacity) ++ get_between(events, 0, read_pointer - 2)
  end

  defp get_new_events(_events, read_pointer, write_pointer, _capacity)
       when read_pointer == write_pointer do
    []
  end

  @spec get_between(List.t(), number, number) :: List.t()
  defp get_between(_list, _from_index, to_index) when to_index < 0 do
    []
  end

  @spec get_between(List.t(), number, number) :: List.t()
  defp get_between(list, from_index, to_index) do
    {front_list, _rest} = Enum.split(list, to_index)
    {_rest, inbetween_list} = Enum.split(front_list, from_index)
    inbetween_list
  end
end
