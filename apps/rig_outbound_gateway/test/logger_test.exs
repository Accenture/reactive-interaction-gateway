defmodule RigOutboundGateway.LoggerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  import RigOutboundGateway.Logger, only: [trunc_body: 1]

  # Must be equal to what is set in RigOutboundGateway.Logger:
  @max_body_print_length 200

  describe "body_truncated" do
    test "is a copy of body_raw if body is empty" do
      meta = [body_raw: make_body(0)]
      result = trunc_body(meta)
      assert result[:body_raw] == ""
      assert result[:body_truncated] == ""
    end

    test "is a copy of body_raw if body is short enough" do
      meta = [body_raw: make_body(@max_body_print_length)]
      result = trunc_body(meta)
      assert result[:body_raw] == meta[:body_raw]
      assert result[:body_truncated] == meta[:body_raw]
    end

    test "is a truncated version of body_raw if body is too long" do
      meta = [body_raw: make_body(@max_body_print_length + 1)]
      result = trunc_body(meta)
      raw = result[:body_raw]
      truncated = result[:body_truncated]
      assert String.length(raw) == @max_body_print_length + 1
      assert String.length(truncated) == @max_body_print_length
    end

    test "is not overwritten if already present" do
      meta = [body_raw: "foo", body_truncated: "bar"]
      assert trunc_body(meta) == meta
    end

    def make_body(len) do
      '1234567890'
      |> Stream.cycle()
      |> Enum.take(len)
      |> List.to_string()
    end
  end
end
