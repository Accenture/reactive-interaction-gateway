defmodule RigKafka.Avro do
  @moduledoc """
  TODO
  """

  require Logger
  use Memoize
  use Rig.Config, [:schema_registry_host]

  @spec parse_schema(String.t()) :: {:ok, map()}
  def parse_schema(subject) do
    {:ok, %{"schema" => raw_schema, "id" => id}} = get(subject)
    schema = :avro.decode_schema(raw_schema)
    Logger.debug("Using Avro schema with name=#{subject}")
    {id, schema}
  end

  @spec parse_schema(integer) :: map()
  def parse_schema_by_id(id) do
    {:ok, %{"schema" => raw_schema}} = get_by_id(id)
    schema = :avro.decode_schema(raw_schema)
    Logger.debug("Using Avro schema with id=#{id}")
    schema
  end

  # ---

  @spec decode(any()) :: String.t()
  def decode(data) do
    {id, binary_body} = parse_binary_metadata(data)
    schema = parse_schema_by_id(id)

    decoded_data =
      binary_body
      |> :avro_binary_decoder.decode(schema, fn schema_subject ->
        raise("Incorrect Avro schema=#{schema_subject}")
      end)
      # TODO non JSON
      |> :jsone.encode()

    Logger.debug("Decoded Avro message=#{inspect(decoded_data)}")
    decoded_data
  end

  # ---

  @spec encode({integer, String.t()}, any()) :: list()
  def encode(schema_name, data) do
    data_map = Jason.decode!(data)
    {id, schema} = parse_schema(schema_name)

    kv = encoder(schema, [])
    bin = kv.(schema, deep_map_to_list(data_map))

    convert_to_binary(id, bin)
  end

  # ---

  def convert_to_binary(id, data) do
    IO.iodata_to_binary([
      <<0>>,
      <<id::big-integer-size(32)>>,
      data
    ])
  end

  # ---

  @spec deep_map_to_list(any()) :: list()
  defp deep_map_to_list(m) do
    if is_map(m) do
      Map.to_list(m)
      |> Enum.map(fn {key, value} -> {key, deep_map_to_list(value)} end)
    else
      m
    end
  end

  # ---

  defp parse_binary_metadata(data) when is_binary(data) do
    # TODO: hack
    <<id::40, body::binary>> = data
    {id, body}
  end

  defp parse_binary_metadata(data), do: data

  # ---

  @spec get(String.t()) :: {:ok | :error, map()}
  defmemo get(subject) do
    %{schema_registry_host: schema_registry_host} = config()

    schema_registry_host
    |> Schemex.latest(subject)
  end

  # ---

  @spec get_by_id(integer) :: {:ok | :error, map()}
  defmemo get_by_id(id) do
    %{schema_registry_host: schema_registry_host} = config()

    schema_registry_host
    |> Schemex.schema(id)
  end

  # ---

  @spec encoder(map(), list) :: any
  defmemo encoder(schema, []) do
    :avro.make_encoder(schema, [])
  end
end
