defmodule RigKafka.AvroTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use Memoize

  import FakeServer

  alias FakeServer.Response
  alias RigKafka.Avro

  @env [port: 8081]

  test_with_server "avro encoder should encode plain string value to binary", @env do
    route("/subjects/stringSchema/versions/latest", Response.ok!(~s<{
      "subject": "stringSchema",
      "version": 1,
      "id": 1,
      "schema": "\\"string\\""}>))

    route("/schemas/ids/1", Response.ok!(~s<{
          "schema": "\\"string\\""
        }>))

    body = "simple test message"
    encoded_value = Avro.encode("stringSchema", body)

    assert encoded_value ==
             <<0, 0, 0, 0, 1, 38, 115, 105, 109, 112, 108, 101, 32, 116, 101, 115, 116, 32, 109,
               101, 115, 115, 97, 103, 101>>

    decoded_body = Avro.decode(encoded_value)
    assert decoded_body == "\"simple test message\""
  end

  test_with_server "avro encoder should encode simple value to binary", @env do
    route("/subjects/simpleSchema/versions/latest", Response.ok!(~s<{
      "subject": "simpleSchema",
      "version": 2,
      "id": 2,
      "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"username\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null},{\\"name\\":\\"food\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaFood\\",\\"fields\\":[{\\"name\\":\\"vegetable\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}"
    }>))

    route("/schemas/ids/2", Response.ok!(~s<{
      "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"username\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null},{\\"name\\":\\"food\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaFood\\",\\"fields\\":[{\\"name\\":\\"vegetable\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}"
    }>))

    body = %{"username" => "Jeff", "food" => %{"vegetable" => "tomato"}}
    encoded_value = Avro.encode("simpleSchema", body)

    assert encoded_value ==
             <<0, 0, 0, 0, 2, 2, 8, 74, 101, 102, 102, 2, 12, 116, 111, 109, 97, 116, 111>>

    decoded_body = Avro.decode(encoded_value)
    assert decoded_body == "{\"username\":\"Jeff\",\"food\":{\"vegetable\":\"tomato\"}}"
  end

  test_with_server "avro encoder should encode deep nested value to binary", @env do
    route("/subjects/nestedSchema/versions/latest", Response.ok!(~s<{
      "subject": "nestedSchema",
      "version": 3,
      "id": 3,
      "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"nestedSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"level1\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaLevel1\\",\\"fields\\":[{\\"name\\":\\"level2\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"undefinedLevel2\\",\\"fields\\":[{\\"name\\":\\"level3\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}}]}"
    }>))

    route("/schemas/ids/3", Response.ok!(~s<{
      "schema": "{\\"type\\":\\"record\\",\\"name\\":\\"nestedSchema\\",\\"doc\\":\\"\\",\\"fields\\":[{\\"name\\":\\"level1\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"simpleSchemaLevel1\\",\\"fields\\":[{\\"name\\":\\"level2\\",\\"type\\":{\\"type\\":\\"record\\",\\"name\\":\\"undefinedLevel2\\",\\"fields\\":[{\\"name\\":\\"level3\\",\\"type\\":[\\"null\\",\\"string\\"],\\"default\\":null}]}}]}}]}"
    }>))

    body = %{"level1" => %{"level2" => %{"level3" => "level3 value"}}}
    encoded_value = Avro.encode("nestedSchema", body)

    assert encoded_value ==
             <<0, 0, 0, 0, 3, 2, 24, 108, 101, 118, 101, 108, 51, 32, 118, 97, 108, 117, 101>>

    decoded_body = Avro.decode(encoded_value)
    assert decoded_body == "{\"level1\":{\"level2\":{\"level3\":\"level3 value\"}}}"
  end
end
