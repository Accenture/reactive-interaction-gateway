defmodule RigKafka.Serializer do
  @moduledoc """
  Interface for event serialization and deserialization. Used to decide which serializer to use, such as Apache Avro.
  """

  alias RigKafka.Avro

  @typep encode_type :: String.t()
  @typep schema_name :: String.t()
  @typep kafka_headers :: list()

  @prefix "ce-"

  # ---

  @spec decode_body!(any(), encode_type, opts :: []) :: any()
  def decode_body!(body, "avro", opts) do
    case opts[:schema_registry_host] do
      nil -> raise "cannot decode avro message: schema registry host not set"
      schema_registry_host -> Avro.decode(body, schema_registry_host)
    end
  end

  # ---

  @spec encode_body(any(), encode_type, schema_name) :: any()
  def encode_body(body, "avro", schema_name, schema_registry_host) do
    schema_name
    |> Avro.encode(body, schema_registry_host)
  end

  def encode_body(body, nil, _schema), do: body

  # ---

  defp query?(value) do
    value
    |> Map.values()
    |> Enum.member?(nil)
    |> Kernel.not()
  end

  # ---

  @spec remove_prefix(kafka_headers) :: map()
  def remove_prefix(headers) do
    for {key, value} <- headers do
      if String.starts_with?(key, @prefix) do
        stripped_key =
          key
          |> String.replace_prefix(@prefix, "")

        decoded_value =
          case Jason.decode(value) do
            {:ok, val} -> val
            _ -> value
          end

        if is_map(decoded_value) && query?(decoded_value) do
          {stripped_key, decoded_value}
        else
          {stripped_key, value}
        end
      else
        {key, value}
      end
    end
    |> Enum.into(%{})
  end

  # ---

  @spec add_prefix(map()) :: kafka_headers
  def add_prefix(headers) do
    for {key, value} <- headers do
      if is_map(value) do
        {"#{@prefix}#{key}", Jason.encode!(value)}
      else
        {"#{@prefix}#{key}", value}
      end
    end
  end
end
