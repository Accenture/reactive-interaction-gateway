defmodule RigInboundGatewayWeb.EventBuffer do
  @moduledoc """
  A simple EventBuffer implementing the circular buffer pattern
  """
  alias __MODULE__

  defstruct [:max_size, :events, :read_pointer, :write_pointer]

  @doc """
  creates a new EventBuffer with the given max_size

  ## Examples
    iex> eb = EventBuffer.new(2)
    %RigInboundGatewayWeb.EventBuffer{events: [], max_size: 2, read_pointer: 0, write_pointer: 0}
  """
  @spec new(number) :: EventBuffer.t()
  def new(max_size) do
    %EventBuffer{max_size: max_size, events: [], read_pointer: 0, write_pointer: 0}
  end

  @doc """
  writes a value to the given EventBuffer, overwrites the oldest value if EventBuffer is full
  """

  @spec write(EventBuffer.t(), any()) :: EventBuffer.t()
  def write(
        %{
          read_pointer: read_pointer,
          write_pointer: write_pointer,
          max_size: max_size,
          events: events
        } = list,
        entry
      ) do
    {write_pointer, read_pointer} =
      if write_pointer === max_size && read_pointer === 0 do
        {0, 1}
      else
        if write_pointer === max_size do
          {0, read_pointer}
        else
          {write_pointer, read_pointer}
        end
      end

    events = insert_or_update(events, write_pointer, entry)
    write_pointer = write_pointer + 1

    # When write_pointer is overtaking read_pointer on write - keep it synced 
    read_pointer = if read_pointer === write_pointer, do: write_pointer + 1, else: read_pointer
    read_pointer = if read_pointer === max_size, do: 0, else: read_pointer

    %EventBuffer{
      list
      | read_pointer: read_pointer,
        write_pointer: write_pointer,
        events: events
    }
  end

  @doc """
  provides the next value from the EventBuffer from current read_pointer
  """
  @spec read(EventBuffer.t()) :: {atom, EventBuffer.t(), any()}
  def read(
        list = %{
          max_size: max_size,
          read_pointer: read_pointer,
          write_pointer: write_pointer,
          events: events
        }
      ) do
    if(read_pointer !== write_pointer) do
      event = Enum.at(events, read_pointer)
      read_pointer = read_pointer + 1
      read_pointer = if read_pointer === max_size, do: 0, else: read_pointer

      {:ok, %EventBuffer{list | read_pointer: read_pointer}, event}
    else
      {:ok, list, []}
    end
  end

  @doc """
  provides the all unread values from the EventBuffer from current read_pointer
  """
  @spec read_all(EventBuffer.t()) :: {atom, EventBuffer.t(), any()}
  def read_all(
        list = %{
          max_size: max_size,
          read_pointer: read_pointer,
          write_pointer: write_pointer,
          events: events
        }
      ) do
    if(read_pointer < write_pointer) do
      new_events = get_between(events, read_pointer, write_pointer)
      read_pointer = write_pointer

      {:ok, %EventBuffer{list | read_pointer: read_pointer}, new_events}
    else
      if(read_pointer > write_pointer) do
        events_to_size = get_between(events, read_pointer, max_size)
        events_to_pointer = get_between(events, 0, write_pointer)
        events_flatten = List.flatten(events_to_size, events_to_pointer)
        read_pointer = write_pointer

        {:ok, %EventBuffer{list | read_pointer: read_pointer}, events_flatten}
      else
        {:ok, list, []}
      end
    end
  end

  @doc """
  provides the next value from the EventBuffer from a given read_pointer
  """
  @spec read_at(EventBuffer.t(), number) :: {atom, EventBuffer.t(), any()}
  def read_at(
        list = %{
          max_size: max_size,
          write_pointer: write_pointer,
          events: events
        },
        read_pointer
      ) do
    if(read_pointer !== write_pointer) do
      event = Enum.at(events, read_pointer)
      read_pointer = read_pointer + 1
      read_pointer = if read_pointer === max_size, do: 0, else: read_pointer

      {:ok, %EventBuffer{list | read_pointer: read_pointer}, event}
    else
      {:ok, list, []}
    end
  end

  @doc """
  provides the all unread values from the EventBuffer from a given read_pointer
  """
  @spec read_all_at(EventBuffer.t(), number) :: {atom, EventBuffer.t(), any()}
  def read_all_at(
        list = %{
          max_size: max_size,
          write_pointer: write_pointer,
          events: events
        },
        read_pointer
      ) do
    if(read_pointer < write_pointer) do
      new_events = get_between(events, read_pointer, write_pointer)
      read_pointer = write_pointer

      {:ok, %EventBuffer{list | read_pointer: read_pointer}, new_events}
    else
      if(read_pointer > write_pointer) do
        events_to_size = get_between(events, read_pointer, max_size)
        events_to_pointer = get_between(events, 0, write_pointer)

        read_pointer = write_pointer

        {:ok, %EventBuffer{list | read_pointer: read_pointer},
         [events_to_size | events_to_pointer]}
      else
        {:ok, list, []}
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

  @spec get_between(List.t(), number, number) :: List.t()
  defp get_between(list, from_index, to_index) do
    {front_list, _rest} = Enum.split(list, to_index)
    {_rest, inbetween_list} = Enum.split(front_list, from_index)
    inbetween_list
  end
end
