defmodule RigCloudEvents.Parser.FullParser do
  @moduledoc """
  Fast reader for JSON encoded CloudEvents.

  Interprets the passed data structure in full once. Field access is done on the
  resulting data structure.
  """
  @behaviour RigCloudEvents.Parser
  alias RigCloudEvents.Parser

  alias Jason
  alias JSONPointer

  @type t :: map

  @impl true
  @spec parse(Parser.json_string()) :: t
  defdelegate parse(json), to: Jason, as: :decode!

  # ---

  @impl true
  @spec context_attribute(t, Parser.attribute()) ::
          {:ok, value :: any}
          | {:error, {:not_found, Parser.attribute(), t}}
          | {:error, {:non_scalar_value, Parser.attribute(), t}}
  def context_attribute(map, attr_name), do: value(map, attr_name)

  # ---

  @impl true
  @spec extension_attribute(t, Parser.extension(), Parser.attribute()) ::
          {:ok, value :: any}
          | {:error, {:not_found, Parser.attribute(), t}}
          | {:error, {:not_an_object | :non_scalar_value, Parser.attribute(), t}}
  def extension_attribute(map, extension_name, attr_name) do
    with {:ok, extension_map} <- object(map, extension_name),
         {:ok, value} <- value(extension_map, attr_name) do
      {:ok, value}
    else
      {:error, error} -> {:error, error}
    end
  end

  # ---

  defp value(map, key) do
    case Map.fetch(map, key) do
      {:ok, val} when not is_map(val) and not is_list(val) -> {:ok, val}
      {:ok, _} -> {:error, {:non_scalar_value, key, map}}
      :error -> {:error, {:not_found, key, map}}
    end
  end

  # ---

  defp object(map, key) do
    case Map.fetch(map, key) do
      {:ok, val} when is_map(val) -> {:ok, val}
      {:ok, _} -> {:error, {:not_an_object, key, map}}
      :error -> {:error, {:not_found, key, map}}
    end
  end

  # ---

  @impl true
  @spec find_value(t, Parser.json_pointer()) ::
          {:ok, value :: any}
          | {:error, {:not_found, location :: String.t(), t}}
          | {:error, {:non_scalar_value, location :: String.t(), t}}
          | {:error, any}
  def find_value(map, json_pointer) do
    case JSONPointer.get(map, json_pointer) do
      {:ok, val} when not is_map(val) and not is_list(val) -> {:ok, val}
      {:ok, _} -> {:error, {:non_scalar_value, json_pointer, map}}
      {:error, "token not found: " <> token} -> {:error, {:not_found, token, map}}
    end
  end
end
