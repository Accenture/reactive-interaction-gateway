defmodule Rig.ConnectionCodecTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest Rig.Connection.Codec

  use ExUnitProperties

  import Rig.Connection.Codec, only: [serialize: 1, deserialize!: 1]

  property "Serialize and deserialize invert each other" do
    # `check all id <- integer(0..0x7FFF)` does not work on a single node.
    id = 0

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      pid = :c.pid(id, serial, creation)
      assert pid == pid |> serialize() |> deserialize!()
    end
  end

  property "The encoded form is url-safe." do
    bad_chars = :binary.compile_pattern(["#", "/", "?"])

    # `check all id <- integer(0..0x7FFF)` does not work on a single node.
    id = 0

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      refute :c.pid(id, serial, creation) |> serialize() |> String.contains?(bad_chars)
    end
  end
end
