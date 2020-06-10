defmodule RigKafka.SerializerTest do
  @moduledoc false

  use ExUnit.Case, async: false

  alias RigKafka.Serializer

  test "remove_prefix should remove 'ce-' prefix and ignore cases without such prefix" do
    prefixed_headers = [
      {"ce-field1", "value1"},
      {"ce-field2", "value2"},
      {"field3", "value3"}
    ]

    headers_no_prefix = Serializer.remove_prefix(prefixed_headers)

    assert headers_no_prefix == %{
             "field1" => "value1",
             "field2" => "value2",
             "field3" => "value3"
           }
  end

  test "add_prefix should add 'ce-' prefix to all fields" do
    headers = %{field1: "value1", field2: "value2"}
    prefixed_headers = Serializer.add_prefix(headers)

    assert prefixed_headers == [
             {"ce-field1", "value1"},
             {"ce-field2", "value2"}
           ]
  end

  test "add_prefix should transform nested field to query" do
    headers = %{field1: "value1", field2: %{field22: %{field222: "value2"}}}
    prefixed_headers = Serializer.add_prefix(headers)

    assert prefixed_headers == [
             {"ce-field1", "value1"},
             {"ce-field2", "{\"field22\":{\"field222\":\"value2\"}}"}
           ]

    headers_no_prefix = Serializer.remove_prefix(prefixed_headers)

    assert headers_no_prefix == %{
             "field1" => "value1",
             "field2" => %{"field22" => %{"field222" => "value2"}}
           }
  end

  test "decode_body! should raise an error when schema registry is not set" do
    assert_raise RuntimeError,
                 "cannot decode avro message: schema registry host not set",
                 fn ->
                   Serializer.decode_body!(
                     <<0, 0, 0, 0, 1, 38, 115, 105, 109, 112, 108, 101, 32, 116, 101, 115, 116,
                       32, 109, 101, 115, 115, 97, 103, 101>>,
                     "avro",
                     nil
                   )
                 end
  end
end
