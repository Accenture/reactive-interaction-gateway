defmodule Rig.ConnectionCodecTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest Rig.Connection.Codec

  use ExUnitProperties

  import Rig.Connection.Codec, only: [serialize: 1, deserialize!: 1, encrypt: 2, decrypt: 2]

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

  property "Encryption / decryption works for key \"magiccookie\"" do
    id = 0
    key = "magiccookie"

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      pid = :c.pid(id, serial, creation) |> :erlang.term_to_binary
      assert pid == pid |> encrypt(key) |> decrypt(key)
    end
  end

  property "Encryption / decryption works for key of empty string" do
    id = 0
    key = ""

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      pid = :c.pid(id, serial, creation) |> :erlang.term_to_binary
      assert pid == pid |> encrypt(key) |> decrypt(key)
    end
  end

  property "Encryption / decryption works for key \"a\"" do
    id = 0
    key = "a"

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      pid = :c.pid(id, serial, creation) |> :erlang.term_to_binary
      assert pid == pid |> encrypt(key) |> decrypt(key)
    end
  end

  property "Encryption / decryption works for a very long key (90 bytes)" do
    id = 0
    key = "QWErty1234QWErty1234QWErty1234QWErty1234QWErty1234QWErty1234QWErty1234QWErty1234"

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      pid = :c.pid(id, serial, creation) |> :erlang.term_to_binary
      assert pid == pid |> encrypt(key) |> decrypt(key)
    end
  end

  property "Encryption / decryption works for key of integer 0" do
    id = 0
    key = 0

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      pid = :c.pid(id, serial, creation) |> :erlang.term_to_binary
      assert pid == pid |> encrypt(key) |> decrypt(key)
    end
  end

  property "Encryption / decryption works for key of negative integer" do
    id = 0
    key = -123

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      pid = :c.pid(id, serial, creation) |> :erlang.term_to_binary
      assert pid == pid |> encrypt(key) |> decrypt(key)
    end
  end

  property "Encryption / decryption works for key of large integer" do
    id = 0
    key = 12_345_678_901_234_567_890

    check all serial <- integer(0..0x1FFF),
              creation <- integer(0..0x03) do
      pid = :c.pid(id, serial, creation) |> :erlang.term_to_binary
      assert pid == pid |> encrypt(key) |> decrypt(key)
    end
  end
end
