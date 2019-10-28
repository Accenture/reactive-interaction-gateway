defmodule Rig.DiffTest do
  use ExUnit.Case, async: true

  alias Rig.Diff

  describe "Compare two lists of tuples" do
    test "Old list has more items than new list" do
      a = [
        {"John", 18},
        {"Frank", 21},
        {"Ben", 21}
      ]
      
      b = [
        {"John", 18},
        {"Frank", 21},
      ]
      {to_add, to_delete, increase_time} = Diff.compare(a, b)

      assert to_add == []
      assert to_delete == [{"Ben", 21}]
      assert increase_time == [{"John", 18},{"Frank", 21}]
    end

    test "New list has more items than old list" do
      a = [
        {"John", 18},
        {"Frank", 21},
      ]

      b = [
        {"John", 18},
        {"Frank", 21},
        {"Ben", 21},
        {"Matt", 21}
      ]
      {to_add, to_delete, increase_time} = Diff.compare(a, b)

      assert to_add == [{"Ben", 21},{"Matt", 21}]
      assert to_delete == []
      assert increase_time == [{"John", 18},{"Frank", 21}]
    end

    test "New list is equal to old list" do
      a = [
        {"John", 18},
        {"Frank", 21},
      ]

      b = [
        {"John", 18},
        {"Frank", 21},
      ]
      {to_add, to_delete, increase_time} = Diff.compare(a, b)

      assert to_add == []
      assert to_delete == []
      assert increase_time == b
    end

    test "New list is slightly different from old list" do
      a = [
        {"John", 18},
        {"Frank", 21},
      ]

      b = [
        {"John", 18},
        {"Max", 21},
      ]
      {to_add, to_delete, increase_time} = Diff.compare(a, b)

      assert to_add == [{"Max", 21}]
      assert to_delete == [{"Frank", 21}]
      assert increase_time == [{"John", 18}]
    end

    test "New list is different from old list" do
      a = [
        {"John", 18},
        {"Frank", 21},
      ]

      b = [
        {"Alex", 18},
        {"Max", 21},
      ]
      {to_add, to_delete, increase_time} = Diff.compare(a, b)

      assert to_add == [{"Alex", 18}, {"Max", 21}]
      assert to_delete == [{"John", 18}, {"Frank", 21}]
      assert increase_time == []
    end
  end
end