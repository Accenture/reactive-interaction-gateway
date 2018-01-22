defmodule Mix.Tasks.UpdateDocs do
  @moduledoc """
  Uses actual configuration defaults for updating the operator's guide.
  """

  use Mix.Task
  require Logger

  alias Mix.Project

  @header """
  Variable | Description | Default
  -------- | ----------- | -------
  """

  @shortdoc "Uses actual configuration defaults for updating the operator's guide."
  def run(_) do
    resolve_filename()
    |> update_file()
  end

  def resolve_filename do
    if Project.umbrella?() do
      "./guides/operator-guide.md"
    else
      "../../guides/operator-guide.md"
    end
  end

  def update_file(filename, env \\ Application.get_all_env(:rig)) do
    defaults =
      env_defaults(env)
      |> log_duplicate_defaults()
      |> Map.new()

    {above_table, table, below_table} =
      filename
      |> read_file()
      |> find_table_in_text()

    table_list = text_to_list(table)

    keysets = extract_keysets(table_list, defaults)
    log_undocumented_vars(keysets)
    log_documented_but_missing_vars(keysets)

    {table_list, updated_keys} = set_defaults(table_list, defaults)
    log_updated_vars(updated_keys)

    # Write back to disk:
    table = list_to_text(table_list)
    content = above_table <> table <> below_table
    write_file(filename, content)
  end

  def find_table_in_text(text) do
    [above_header, below_header] = String.split(text, @header, parts: 2)
    [table, below_table] = String.split(below_header, "\n\n", parts: 2)
    {above_header <> @header, table, "\n\n" <> below_table}
  end

  def text_to_list(table_text) do
    table_text
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> String.split("|")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&String.trim(&1, "`"))
      |> List.to_tuple()
    end)
  end

  def list_to_text(table_list) do
    table_list
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&Enum.join(&1, " | "))
    |> Enum.join("\n")
  end

  def log_duplicate_defaults(defaults) do
    defaults
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case Map.fetch(acc, key) do
        {:ok, ^value} ->
          # Multiple definitions are okay if the same default is used
          acc

        {:ok, other_value} ->
          Logger.warn(
            "More than one default value found for environment variable #{key}: #{inspect(value)} and #{
              inspect(other_value)
            }"
          )

          acc

        :error ->
          Map.put(acc, key, value)
      end
    end)
  end

  def extract_keysets(table, defaults) do
    table_keyset =
      table
      |> Enum.map(fn {key, _, _} -> key end)
      |> MapSet.new()

    env_keyset =
      defaults
      |> Enum.map(fn {key, _} -> key end)
      |> MapSet.new()

    {table_keyset, env_keyset}
  end

  def log_undocumented_vars({table_keyset, env_keyset}) do
    env_keyset |> MapSet.difference(table_keyset)
    |> Enum.each(fn key ->
      Logger.warn("Documentation for environment variable #{key} is missing")
    end)
  end

  def log_documented_but_missing_vars({table_keyset, env_keyset}) do
    table_keyset |> MapSet.difference(env_keyset)
    |> Enum.each(fn key ->
      Logger.warn("Documentation for environment variable #{key} is missing")
    end)
  end

  def log_updated_vars(updated_keys) do
    updated_keys
    |> Enum.each(fn key ->
      Logger.info("Default value for environment variable #{key} updated")
    end)
  end

  def set_defaults(table_list, defaults) do
    {updated_table, updated_keys} =
      table_list
      |> Enum.reduce({_table = [], _keys = MapSet.new()}, fn {key, desc, last_default},
                                                             {table, keys} = _acc ->
        cur_default_str = Map.get(defaults, key, nil) |> inspect()
        keys = if last_default == cur_default_str, do: keys, else: MapSet.put(keys, key)
        table = table ++ [{"`#{key}`", desc, cur_default_str}]
        {table, keys}
      end)

    {updated_table, updated_keys}
  end

  def env_defaults(env) do
    env
    |> Stream.flat_map(fn {_mod, kwlist} -> kwlist end)
    |> Stream.map(fn
      {_, {:system, key, val}} -> {key, val}
      {_, {:system, _, key, val}} -> {key, val}
      _ -> nil
    end)
    |> Stream.reject(&is_nil/1)
    |> Enum.to_list()
  end

  def read_file(filename) do
    file = File.open!(filename, [:read, :utf8])
    all = IO.read(file, :all)
    File.close(file)
    all
  end

  def write_file(filename, content) do
    file = File.open!(filename, [:write, :utf8])
    IO.write(file, content)
    File.close(file)
  end
end
