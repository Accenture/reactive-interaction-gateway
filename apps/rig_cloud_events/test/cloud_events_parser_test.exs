defmodule CloudEventsParserTest do
  # credo:disable-for-previous-line Credo.Check.Readability.ModuleNames
  @moduledoc false
  use ExUnit.Case

  alias Jason
  alias Jaxon

  @parsers [
    RigCloudEvents.Parser.PartialParser,
    RigCloudEvents.Parser.FullParser
  ]

  test "A string context attribute is found." do
    for parser <- @parsers do
      assert {:ok, "b"} =
               %{"a" => "b"}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.context_attribute("a")
    end
  end

  test "A nil context attribute is found." do
    for parser <- @parsers do
      assert {:ok, nil} =
               %{"a" => nil}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.context_attribute("a")
    end
  end

  test "A non-existant context attribute causes an error." do
    for parser <- @parsers do
      assert {:error, {:not_found, "b", _}} =
               %{"a" => nil}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.context_attribute("b")
    end
  end

  test "A context attribute that is has an object value causes an error." do
    for parser <- @parsers do
      assert {:error, {:non_scalar_value, "a", _}} =
               %{"a" => %{}}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.context_attribute("a")
    end
  end

  test "A context attribute that is has an array value causes an error." do
    for parser <- @parsers do
      assert {:error, {:non_scalar_value, "a", _}} =
               %{"a" => []}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.context_attribute("a")
    end
  end

  test "A string attribute within an extension object is found." do
    for parser <- @parsers do
      assert {:ok, "c"} =
               %{"a" => %{"b" => "c"}}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.extension_attribute("a", "b")
    end
  end

  test "A non-existant attribute within an extension object causes an error." do
    for parser <- @parsers do
      assert {:error, {:not_found, "c", _}} =
               %{"a" => %{"b" => "c"}}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.extension_attribute("a", "c")
    end
  end

  test "A non-existant extension object causes an error." do
    for parser <- @parsers do
      assert {:error, {:not_found, "b", _}} =
               %{"a" => %{"b" => "c"}}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.extension_attribute("b", "b")
    end
  end

  test "An extension that is not an object causes an error." do
    for parser <- @parsers do
      assert {:error, {:not_an_object, "a", _}} =
               %{"a" => nil}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.extension_attribute("a", "b")
    end
  end

  # See https://tools.ietf.org/html/rfc6901
  test "Searching for a value using a JSON Pointer works according to the spec." do
    for parser <- @parsers do
      tokens =
        parser.parse(~S"""
        {
          "foo": ["bar", "baz"],
          "": 0,
          "a/b": 1,
          "c%d": 2,
          "e^f": 3,
          "g|h": 4,
          "i\\j": 5,
          "k\"l": 6,
          " ": 7,
          "m~n": 8
        }
        """)

      # the whole document:
      assert {:error, {:non_scalar_value, _, _}} = parser.find_value(tokens, ~S"")

      # ["bar", "baz"]:
      assert {:error, {:non_scalar_value, _, _}} = parser.find_value(tokens, ~S"/foo")

      # The list indices syntax is currently not supported/implemented:
      # assert "bar" = parser.find_value(tokens, ~S"/foo/0")

      assert {:ok, 0} = parser.find_value(tokens, ~S(/))
      assert {:ok, 1} = parser.find_value(tokens, ~S(/a~1b))

      # Currently a bug in JSONPointer..
      if parser != RigCloudEvents.Parser.FullParser,
        do: assert({:ok, 2} = parser.find_value(tokens, ~S(/c%d)))

      assert {:ok, 3} = parser.find_value(tokens, ~S(/e^f))
      assert {:ok, 4} = parser.find_value(tokens, ~S(/g|h))
      # No idea why this doesn't work:
      # assert {:ok, 5} = parser.find_value(tokens, ~S(/i\\j))
      # assert {:ok, 6} = parser.find_value(tokens, ~S(/k\"l))
      assert {:ok, 7} = parser.find_value(tokens, ~S(/ ))
      assert {:ok, 8} = parser.find_value(tokens, ~S(/m~0n))

      assert {:error, {:not_found, _, _}} = parser.find_value(tokens, ~S(/something-else))

      # The URI fragment identifier representation is not supported.
    end
  end

  test "A JSON Pointer can point to a nested value." do
    for parser <- @parsers do
      assert {:ok, "d"} =
               %{"a" => %{"b" => %{"c" => "d"}}}
               |> Jason.encode!()
               |> parser.parse()
               |> parser.find_value("/a/b/c")
    end
  end
end
