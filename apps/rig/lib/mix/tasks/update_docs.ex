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
    # Read the whole file:
    all = read_file(filename)

    # Look for the table:
    [above_header, below_header] = String.split(all, @header, parts: 2)
    [table, below_table] = String.split(below_header, "\n\n", parts: 2)

    table = update_table(table, env_defaults(env))

    # Write back to disk:
    content = above_header <> @header <> table <> "\n\n" <> below_table
    write_file(filename, content)
  end

  def update_table(table, {defaults, env_keys}) do
    processed_keys = MapSet.new()

    updated =
      table
      |> String.split("\n")
      |> Enum.map(fn line ->
        line
        |> String.split("|")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.trim(&1, "`"))
      end)
      |> Enum.map(fn [key, desc, old_default] ->
        env_keys =
          if Enum.member?(env_keys, key) do
            List.delete(env_keys, key)
          else
            Logger.warn(
              "Encountered an unknown environment variable #{key} in the markdown table"
            )

            env_keys
          end

        processed_keys = MapSet.put(processed_keys, key)

        default =
          case get_default(defaults, key) do
            {:ok, new_default} -> inspect(new_default)
            :notfound -> old_default
          end

        ["`#{key}`", desc, default]
      end)
      |> Enum.map(&Enum.join(&1, " | "))
      |> Enum.join("\n")

    case env_keys do
      [] ->
        :ok

      _ ->
        env_keys
        |> Enum.each(fn key ->
          if MapSet.member?(processed_keys, key) do
            Logger.warn("More than one default value found for environment variable #{key}")
          else
            Logger.warn("Documentation for environment variable #{key} is missing")
          end
        end)
    end

    updated
  end

  def env_defaults(env) do
    defaults =
      env
      |> Stream.flat_map(fn {_mod, kwlist} -> kwlist end)
      |> Stream.map(fn
        {_, {:system, key, val}} -> {key, val}
        {_, {:system, _, key, val}} -> {key, val}
        _ -> nil
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()

    env_keys =
      defaults
      |> Enum.map(fn {key, _val} -> key end)

    {Map.new(defaults), env_keys}
  end

  def get_default(defaults, key) do
    case Map.fetch(defaults, key) do
      {:ok, val} ->
        {:ok, val}

      :error ->
        Logger.warn("No default value found for environment variable #{key}")
        :notfound
    end
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
