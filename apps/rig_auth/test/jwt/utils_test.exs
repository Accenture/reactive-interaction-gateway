defmodule RigAuth.Jwt.UtilsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use RigAuth.ConnCase

  alias RigAuth.Jwt.Utils

  describe "valid_scope?/3" do
    test "should return true with valid action" do
      jwt = generate_jwt(["testAction"])
      assert Utils.valid_scope?([jwt], "rg", "testAction")
    end

    test "should return false with invalid action" do
      jwt = generate_jwt(["invalidAction"])
      refute Utils.valid_scope?([jwt], "rg", "testAction")
    end
  end

  describe "decode/1" do
    test "should return decoded jwt payload with valid jwt" do
      jwt = generate_jwt()
      assert {:ok, _decoded_payload} = Utils.decode(jwt)
    end

    test "should return error with invalid jwt" do
      jwt = "badtoken"
      assert {:error, "Invalid signature"} = Utils.decode(jwt)
    end
  end

  describe "valid?/1" do
    test "should return true with valid jwt" do
      jwt = generate_jwt()
      assert Utils.valid?(jwt)
    end

    test "should return false with invalid jwt" do
      jwt = "badtoken"
      refute Utils.valid?(jwt)
    end
  end
end
