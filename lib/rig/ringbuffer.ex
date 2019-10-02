defmodule Rig.RingBuffer do
  @moduledoc false

  defstruct [:max_size, :entries, :size]

  alias Rig.RingBuffer

  def new(max_size) do
    %RingBuffer{max_size: max_size, entries: [], size: 0}
  end

  def add(%{size: size, max_size: size, entries: [_oldest | tail]} = list, entry) do
    %RingBuffer{list | entries: tail ++ [entry]}
  end

  def add(%{size: size, entries: entries} = list, entry) do
    %RingBuffer{list | size: size + 1, entries: entries ++ [entry]}
  end

  def entries(%{entries: entries}), do: entries
end
