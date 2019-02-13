defmodule RigKafka.AvroTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Memoize

  import FakeServer

  alias FakeServer.Response
  alias RigKafka.Avro

  @env [port: 8081]

  test_with_server "avro parse_schema should correctly parse schema", @env do
    route("/subjects/stringSchema/versions/latest", Response.ok!(~s<{
      "subject": "stringSchema",
      "version": 1,
      "id": 1,
      "schema": "\\"string\\""}>))

    assert Avro.parse_schema("stringSchema") == {1, {:avro_primitive_type, "string", []}}
  end

  # test_with_server "avro encoder should encode plain string value to binary", @env do
  #   route("/subjects/stringSchema/versions/latest", Response.ok!(~s<{
  #     "subject": "stringSchema",
  #     "version": 1,
  #     "id": 1,
  #     "schema": "\\"string\\""}>))

  #   body = "simple test message"
  #   encoded_value = Avro.encode("stringSchema", body)
  #   assert encoded_value == ['&', "simple test message"]

  #   parsed_schema = Avro.parse_schema("stringSchema")
  #   decoded_body = Avro.decode(parsed_schema, encoded_value)
  #   assert decoded_body == "\"simple test message\""
  # end

  test_with_server "avro encoder should encode value to binary", @env do
    route("/subjects/simpleSchema/versions/latest", Response.ok!(~s<{
      "subject": "simpleSchema",
      "version": 1,
      "id": 1,
      "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"username\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null},{\\"name\\":\\"food\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaFood\\",\\"fields\\":[{\\"name\\":\\"vegetable\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}"
    }>))

    route("/schemas/ids/1", Response.ok!(~s<{
      "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"username\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null},{\\"name\\":\\"food\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaFood\\",\\"fields\\":[{\\"name\\":\\"vegetable\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}"
    }>))

    body = %{"username" => "Jeff", "food" => %{"vegetable" => "tomato"}}
    encoded_value = Avro.encode("simpleSchema", Jason.encode!(body))

    assert encoded_value ==
             <<0, 0, 0, 0, 1, 2, 8, 74, 101, 102, 102, 2, 12, 116, 111, 109, 97, 116, 111>>

    decoded_body = Avro.decode(encoded_value)
    assert decoded_body == "{\"username\":\"Jeff\",\"food\":{\"vegetable\":\"tomato\"}}"
  end

  test_with_server "avro encoder should encode deep nested value to binary", @env do
    route("/subjects/nestedSchema/versions/latest", Response.ok!(~s<{
      "subject": "nestedSchema",
      "version": 1,
      "id": 1,
      "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"nestedSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"level1\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaLevel1\\",\\"fields\\":[{\\"name\\":\\"level2\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"undefinedLevel2\\",\\"fields\\":[{\\"name\\":\\"level3\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}}]}"
    }>))

    route("/schemas/ids/1", Response.ok!(~s<{
      "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"nestedSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"level1\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaLevel1\\",\\"fields\\":[{\\"name\\":\\"level2\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"undefinedLevel2\\",\\"fields\\":[{\\"name\\":\\"level3\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}}]}"
    }>))

    body = %{"level1" => %{"level2" => %{"level3" => "level3 value"}}}
    encoded_value = Avro.encode("nestedSchema", Jason.encode!(body))

    assert encoded_value ==
             <<0, 0, 0, 0, 1, 2, 24, 108, 101, 118, 101, 108, 51, 32, 118, 97, 108, 117, 101>>

    decoded_body = Avro.decode(encoded_value)
    assert decoded_body == "{\"level1\":{\"level2\":{\"level3\":\"level3 value\"}}}"
  end
end
