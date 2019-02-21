defmodule RigKafka.Avro do
  @moduledoc """
  TODO
  """

  require Logger
  use Memoize
  use Rig.Config, [:schema_registry_host]

  @typep schema_name :: String.t()
  @typep schema :: map()
  @typep avro_binary :: binary()
  @typep id :: integer

  @spec decode(any()) :: String.t()
  def decode(data) do
    {id, binary_body} = parse_binary_metadata(data)
    schema = fetch_schema_by_id(id)

    decoded_data =
      binary_body
      |> :avro_binary_decoder.decode(schema, fn schema_subject ->
        raise("Incorrect Avro schema=#{schema_subject}")
      end)
      |> :jsone.encode()

    Logger.debug(fn -> "Decoded Avro message=#{inspect(decoded_data)}" end)
    decoded_data
  end

  # ---

  @spec encode(schema_name, any()) :: avro_binary
  def encode(schema_name, data) do
    {id, schema} = fetch_schema_by_name(schema_name)

    kv = encoder(schema, [])
    bin = kv.(schema, deep_map_to_list(data))

    convert_to_binary(id, bin)
  end

  # ---

  @spec convert_to_binary(id, any()) :: avro_binary
  defp convert_to_binary(id, data) do
    IO.iodata_to_binary([
      <<0>>,
      <<id::big-integer-size(32)>>,
      data
    ])
  end

  # ---

  # Since we are using erlavro library, functions for encode can't deal with Elixir maps,
  # thus we need to transform deep nested maps to deep nested list
  @spec deep_map_to_list(any()) :: list()
  defp deep_map_to_list(m) when is_map(m) do
    m
    |> Map.to_list()
    |> Enum.map(fn {key, value} -> {key, deep_map_to_list(value)} end)
  end

  defp deep_map_to_list(m), do: m

  # ---

  @spec parse_binary_metadata(avro_binary) :: {id, String.t()}
  defp parse_binary_metadata(<<0::8, id::32, body::binary>>), do: {id, body}

  defp parse_binary_metadata(data), do: data

  # ---

  @spec fetch_schema_by_name(schema_name) :: {id, schema}
  defmemo fetch_schema_by_name(subject) do
    %{schema_registry_host: schema_registry_host} = config()

    {:ok, %{"schema" => raw_schema, "id" => id}} =
      schema_registry_host
      |> Schemex.latest(subject)

    schema = :avro.decode_schema(raw_schema)
    Logger.debug(fn -> "Using Avro schema with name=#{subject}" end)
    {id, schema}
  end

  @spec fetch_schema_by_id(id) :: schema
  defmemo fetch_schema_by_id(id) do
    %{schema_registry_host: schema_registry_host} = config()

    {:ok, %{"schema" => raw_schema}} =
      schema_registry_host
      |> Schemex.schema(id)

    schema = :avro.decode_schema(raw_schema)
    Logger.debug(fn -> "Using Avro schema with id=#{id}" end)
    schema
  end

  # ---

  @spec encoder(schema, list) :: any()
  defmemo encoder(schema, []) do
    :avro.make_encoder(schema, [])
  end
end
