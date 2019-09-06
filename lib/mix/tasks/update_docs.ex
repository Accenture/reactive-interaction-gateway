defmodule Mix.Tasks.UpdateDocs do
  @moduledoc """
  Uses actual configuration defaults for updating the operator's guide.
  """

  use Mix.Task
  require Logger

  @header """
  -------- | ----------- | -------
  """

  @erlang_envs ["NODE_HOST", "NODE_COOKIE"]

  @target_path "./docs/rig-ops-guide.md"

  @shortdoc "Uses actual configuration defaults for updating the operator's guide."
  def run(_) do
    # Only run when MIX_ENV=PROD for correct default values:
    if Mix.env() == :prod do
      if File.exists?(@target_path) do
        update_file(@target_path)
      else
        Logger.info(fn -> "Not updating documentation (file not present: #{@target_path})" end)
      end
    end
  end

  defp all_envs do
    Application.get_all_env(:rig)
  end

  def update_file(filename, env \\ all_envs()) do
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
    env_keyset
    |> MapSet.difference(table_keyset)
    |> Enum.each(fn key ->
      Logger.warn("Documentation for environment variable #{key} is missing")
    end)
  end

  def log_documented_but_missing_vars({table_keyset, env_keyset}) do
    @erlang_envs
    |> MapSet.new()
    |> MapSet.difference(table_keyset)
    |> MapSet.difference(env_keyset)
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

  defp nested_envs(envs) do
    {flat_env, list_env} =
      Enum.split_with(envs, fn
        {_, _} -> true
        _ -> false
      end)

    list_env
    |> List.flatten()
    |> Enum.concat(flat_env)
    |> Enum.reject(&is_nil/1)
  end

  def env_defaults(env) do
    env
    |> Enum.flat_map(fn {_mod, kwlist} -> List.wrap(kwlist) end)
    |> Enum.map(fn
      {_, {:system, key, val}} ->
        {key, val}

      {_, {:system, _, key, val}} ->
        {key, val}

      {_, list_env = [_ | _]} ->
        Enum.map(list_env, fn
          {_, {:system, key, val}} -> {key, val}
          {_, {:system, _, key, val}} -> {key, val}
          _ -> nil
        end)

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
    |> nested_envs
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
