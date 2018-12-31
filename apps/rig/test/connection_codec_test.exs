defmodule Rig.ConnectionCodecTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest Rig.Connection.Codec

  import Rig.Connection.Codec, only: [serialize: 1, deserialize!: 1]

  test "Serialize and deserialize invert each other" do
    pid = self()
    assert pid == pid |> serialize() |> deserialize!()
  end

  test "The encoded form is url-encoded." do
    assert :c.pid(0, 764, 0) |> serialize() |> String.contains?("%2F")
  end
end
