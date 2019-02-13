defmodule RigKafka.AvroTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Memoize
  alias RigKafka.Avro

  setup do
    # Clean schema registry cache before every test
    Memoize.invalidate()
    boot_service(Bypass.open(port: 8081))
  end

  defp boot_service(kafka_schema_registry) do
    case kafka_schema_registry do
      {:error, :eaddrinuse} -> boot_service(Bypass.open(port: 8081))
      # Retry for new instance if previous didn't manage to exit
      _ -> {:ok, kafka_schema_registry: kafka_schema_registry}
    end
  end

  test "avro parse_schema should correctly parse schema", %{
    kafka_schema_registry: kafka_schema_registry
  } do
    Bypass.expect(
      kafka_schema_registry,
      "GET",
      "/subjects/stringSchema/versions/latest",
      fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{
          "subject": "stringSchema",
          "version": 1,
          "id": 1,
          "schema": "\\"string\\""}>)
      end
    )

    assert Avro.parse_schema("stringSchema") == {:avro_primitive_type, "string", []}
  end

  test "avro encoder should encode plain string value to binary", %{
    kafka_schema_registry: kafka_schema_registry
  } do
    Bypass.expect(
      kafka_schema_registry,
      "GET",
      "/subjects/stringSchema/versions/latest",
      fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{
          "subject": "stringSchema",
          "version": 1,
          "id": 1,
          "schema": "\\"string\\""}>)
      end
    )

    body = "simple test message"
    encoded_value = Avro.encode("stringSchema", body)
    assert encoded_value == ['&', "simple test message"]

    parsed_schema = Avro.parse_schema("stringSchema")
    decoded_body = Avro.decode(parsed_schema, encoded_value)
    assert decoded_body == "\"simple test message\""
  end

  test "avro encoder should encode value to binary", %{
    kafka_schema_registry: kafka_schema_registry
  } do
    Bypass.expect(
      kafka_schema_registry,
      "GET",
      "/subjects/simpleSchema/versions/latest",
      fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{
          "subject": "simpleSchema",
          "version": 1,
          "id": 1,
          "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"username\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null},{\\"name\\":\\"food\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaFood\\",\\"fields\\":[{\\"name\\":\\"vegetable\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}"
      }>)
      end
    )

    {"type":"record","name":"simpleSchema","doc":"","fields":[{"name":"username","type":["null","string"],"default":null},{"name":"food","type":{"type":"record","name":"simpleSchemaFood","fields":[{"name":"vegetable","type":["null","string"],"default":null}]}}]}
    {"type":"record","name":"stringSchema","doc":"","fields":[{"name":"source","type":["null","string"],"default":null},{"name":"extensions","type":{"type":"record","name":"stringSchemaExtensions","fields":[]}},{"name":"eventTypeVersion","type":["null","string"],"default":null},{"name":"eventType","type":["null","string"],"default":null},{"name":"eventTime","type":["null","string"],"default":null},{"name":"eventID","type":["null","string"],"default":null},{"name":"data","type":{"type":"record","name":"stringSchemaData","fields":[{"name":"foo","type":["null","string"],"default":null}]}},{"name":"contentType","type":["null","string"],"default":null},{"name":"cloudEventsVersion","type":["null","string"],"default":null}]}

    body = %{"username" => "Jeff", "food" => %{"vegetable" => "tomato"}}
    encoded_value = Avro.encode("simpleSchema", body)
    assert encoded_value == [[[2], ['\b', "Jeff"]], [[[2], ['\f', "tomato"]]]]

    parsed_schema = Avro.parse_schema("simpleSchema")
    decoded_body = Avro.decode(parsed_schema, encoded_value)
    assert decoded_body == "{\"username\":\"Jeff\",\"food\":{\"vegetable\":\"tomato\"}}"
  end

  test "avro encoder should encode deep nested value to binary", %{
    kafka_schema_registry: kafka_schema_registry
  } do
    Bypass.expect(
      kafka_schema_registry,
      "GET",
      "/subjects/nestedSchema/versions/latest",
      fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{
          "subject": "nestedSchema",
          "version": 1,
          "id": 1,
          "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"nestedSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"level1\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaLevel1\\",\\"fields\\":[{\\"name\\":\\"level2\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"undefinedLevel2\\",\\"fields\\":[{\\"name\\":\\"level3\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}}]}"
      }>)
      end
    )

    body = %{"level1" => %{"level2" => %{"level3" => "level3 value"}}}
    encoded_value = Avro.encode("nestedSchema", body)
    assert encoded_value == [[[[[2], [[24], "level3 value"]]]]]

    parsed_schema = Avro.parse_schema("nestedSchema")
    decoded_body = Avro.decode(parsed_schema, encoded_value)
    assert decoded_body == "{\"level1\":{\"level2\":{\"level3\":\"level3 value\"}}}"
  end

  test "avro decoder should strip metadata from binary", %{
    kafka_schema_registry: kafka_schema_registry
  } do
    Bypass.expect(
      kafka_schema_registry,
      "GET",
      "/subjects/simpleSchema/versions/latest",
      fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{
          "subject": "simpleSchema",
          "version": 1,
          "id": 1,
          "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"username\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null},{\\"name\\":\\"food\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaFood\\",\\"fields\\":[{\\"name\\":\\"vegetable\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}"
      }>)
      end
    )

    # binary encoded with schema => %{"username" => "Jeff", "food" => %{"vegetable" => "tomato"}}
    encoded_value = <<0, 0, 0, 0, 6, 2, 8, 74, 101, 102, 102, 2, 12, 116, 111, 109, 97, 116, 111>>

    parsed_schema = Avro.parse_schema("simpleSchema")
    decoded_body = Avro.decode(parsed_schema, encoded_value)
    assert decoded_body == "{\"username\":\"Jeff\",\"food\":{\"vegetable\":\"tomato\"}}"
  end

  # test "avro decoder should throw error with wrong schema", %{kafka_schema_registry: kafka_schema_registry} do
  #   Bypass.expect kafka_schema_registry, "GET", "/subjects/stringSchema/versions/latest", fn conn ->
  #     Plug.Conn.resp(conn, 200, ~s<{
  #       "subject": "stringSchema",
  #       "version": 1,
  #       "id": 1,
  #       "schema": "\\"string\\""}>)
  #   end

  #   parsed_schema = Avro.parse_schema("stringSchema")
  #   assert_raise RuntimeError, Avro.decode("parsed_schema", ['&', "simple test message"])
  # end
end
