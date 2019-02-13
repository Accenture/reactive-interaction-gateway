defmodule RigKafka.Serializer do
  @moduledoc """
  TODO
  """

  alias RigKafka.Avro

  @spec decode_body(String.t(), String.t()) :: map()
  def decode_body(body, nil), do: body

  def decode_body(body, "avro") do
    Avro.decode(body)
  end

  @spec encode_body(String.t(), String.t(), String.t()) :: String.t()
  def encode_body(body, nil, _schema), do: body

  def encode_body(body, "avro", schema_name) do
    schema_name
    |> Avro.encode(body)
  end
end
