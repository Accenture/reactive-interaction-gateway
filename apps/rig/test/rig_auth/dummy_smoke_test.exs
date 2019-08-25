defmodule RigAuth.DummySmokeTest do
  @moduledoc "Prevents a warning as long as there is no smoke test in this app."
  use ExUnit.Case, async: true

  describe "dummy" do
    @tag :smoke
    test "nothing" do
      nil
    end
  end
end
