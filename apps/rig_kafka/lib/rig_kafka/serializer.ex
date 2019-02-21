defmodule RigKafka.Serializer do
  @moduledoc """
  TODO
  """

  alias RigKafka.Avro

  @typep encode_type :: String.t()
  @typep schema_name :: String.t()

  @spec decode_body(any(), encode_type) :: any()
  def decode_body(body, "avro") do
    Avro.decode(body)
  end

  def decode_body(body, nil), do: body

  # ---

  @spec encode_body(any(), encode_type, schema_name) :: any()
  def encode_body(body, "avro", schema_name) do
    schema_name
    |> Avro.encode(body)
  end

  def encode_body(body, nil, _schema), do: body
end
