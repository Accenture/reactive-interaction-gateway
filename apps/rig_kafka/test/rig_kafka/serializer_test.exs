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
    assert headers_no_prefix == %{field1: "value1", field2: "value2", field3: "value3"}
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
             field1: "value1",
             field2: %{"field22" => %{"field222" => "value2"}}
           }
  end
end
