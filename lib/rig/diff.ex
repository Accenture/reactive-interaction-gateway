defmodule Rig.Diff do
  @moduledoc """
  Compare two lists of tuples
  """
  defp any(a, x) do
    unless Enum.any?(a, fn y ->
      x == y
    end) do
      x
    end
  end

  defp get_diff(a, b) do
    Enum.map(b, fn x ->
      any(a, x)
    end)
    |> Enum.reject(&is_nil/1)
  end

  def compare(a, b) do
    to_add = get_diff(a, b)
    to_delete = get_diff(b, a)
    increase_time = get_diff(to_add, b)

    {to_add, to_delete, increase_time}
  end
end
