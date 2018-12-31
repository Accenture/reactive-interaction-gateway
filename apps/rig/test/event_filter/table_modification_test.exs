defmodule Rig.EventFilter.TableModificationTest do
  @moduledoc false
  use ExUnit.Case, async: false

  alias Rig.EventFilter.Server, as: SUT

  describe "Wildcards" do
    test "are not applied to an empty ETS table" do
      table = new_table()
      SUT.add_wildcards_to_table(table, 0, 1)
      assert :ets.info(table)[:size] == 0
      :ets.delete(table)
    end

    test "adds wildcards to each row in a non-empty ETS table" do
      table = new_table()
      insert_row(table, [])
      SUT.add_wildcards_to_table(table, 0, 1)
      assert :ets.info(table)[:size] == 1
      :ets.delete(table)
    end
  end

  defp new_table, do: :ets.new(:test, [:bag, :public])

  defp insert_row(table, fields) do
    pid = self()
    exp = 123
    row = ([pid, exp] ++ fields) |> List.to_tuple()
    :ets.insert(table, row)
    table
  end
end
