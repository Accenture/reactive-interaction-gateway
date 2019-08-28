defmodule RigCloudEvents.Parser.PartialParser do
  @moduledoc """
  Error-tolerant reader for JSON encoded CloudEvents.

  Interprets the passed data structure as little as possible. The idea comes from the
  CloudEvents spec that states that JSON payloads ("data") are encoded along with the
  envelope ("context attributes"). This parser only interprets fields that are
  required for RIG to operate and skips the (potentially large) data payload.
  """
  @behaviour RigCloudEvents.Parser
  alias RigCloudEvents.Parser

  alias Jaxon.Event, as: JaxonToken
  alias Jaxon.Parser, as: JaxonParser

  @type t :: [JaxonToken.t()]

  @impl true
  @spec parse(Parser.json_string()) :: t
  defdelegate parse(json), to: JaxonParser

  # ---

  @impl true
  @spec context_attribute(t, Parser.attribute()) ::
          {:ok, value :: any}
          | {:error, {:not_found, Parser.attribute(), t}}
          | {:error, {:non_scalar_value, Parser.attribute(), t}}
          | {:error, any}
  def context_attribute(tokens, attr_name) do
    value(tokens, attr_name)
  end

  # ---

  @impl true
  @spec extension_attribute(
          t,
          Parser.extension(),
          Parser.attribute()
        ) ::
          {:ok, value :: any}
          | {:error, {:not_found, Parser.attribute(), t}}
          | {:error, {:not_an_object | :non_scalar_value, Parser.attribute(), t}}
          | {:error, any}
  def extension_attribute(tokens, extension_name, attr_name) do
    case apply_lens(tokens, extension_name) do
      [] -> {:error, {:not_found, extension_name, tokens}}
      [:start_object | _] = extension -> value(extension, attr_name)
      tokens -> {:error, {:not_an_object, extension_name, tokens}}
    end
  end

  # ---

  @impl true
  @spec find_value(t, Parser.json_pointer()) ::
          {:ok, value :: any}
          | {:error, {:not_found, location :: String.t(), t}}
          | {:error, {:non_scalar_value, location :: String.t(), t}}
          | {:error, any}

  def find_value(json_tokens, "/" <> json_pointer) do
    # See https://tools.ietf.org/html/rfc6901#section-4
    reference_tokens =
      for token <- String.split(json_pointer, "/"),
          do: token |> String.replace("~1", "/") |> String.replace("~0", "~")

    # We can't do much if the pointer goes into data and data is encoded..
    if points_into_encoded_data(json_tokens, reference_tokens) do
      {:error, :cannot_extract_from_encoded_data}
    else
      do_find_value(json_tokens, reference_tokens)
    end
  end

  def find_value(tokens, "" = _the_whole_document),
    do: {:error, {:non_scalar_value, "", tokens}}

  def find_value(_tokens, "#" <> _),
    do: raise("The URI fragment identifier representation is not supported.")

  # ---

  defp points_into_encoded_data(json_tokens, reference_tokens)

  defp points_into_encoded_data(json_tokens, [ref_token | rest])
       when ref_token == "data" and rest != [] do
    # `data` is encoded if, and only if, `contenttype` is set.
    case value(json_tokens, "contenttype") do
      {:error, {:not_found, _, _}} ->
        # `contenttype` is not set, so `data` must be already parsed.
        false

      {:ok, _} ->
        # `contenttype` is set, so `data` is still encoded.
        true
    end
  end

  defp points_into_encoded_data(_, _), do: false

  # ---

  defp do_find_value(json_tokens, reference_tokens)

  defp do_find_value(json_tokens, [ref_token | []]),
    do: value(json_tokens, ref_token)

  defp do_find_value(json_tokens, [ref_token | remaining_ref_tokens]),
    do: apply_lens(json_tokens, ref_token) |> do_find_value(remaining_ref_tokens)

  # ---

  defp value(tokens, prop) do
    case apply_lens(tokens, prop) do
      [] -> {:error, {:not_found, prop, tokens}}
      [{:error, error} | _] -> {:error, error}
      [{_, value}] -> {:ok, value}
      [nil] -> {:ok, nil}
      [:start_object | _] = tokens -> {:error, {:non_scalar_value, prop, tokens}}
      [:start_array | _] = tokens -> {:error, {:non_scalar_value, prop, tokens}}
    end
  end

  def apply_lens(tokens, attr_name) do
    case tokens do
      [{:string, ^attr_name} | [:colon | tokens]] -> read_val(tokens)
      [{:string, _key} | [:colon | tokens]] -> skip_val(tokens) |> apply_lens(attr_name)
      [:start_object | tokens] -> apply_lens(tokens, attr_name)
      [:end_object] -> []
      [] -> []
      [{:error, _} | _] -> tokens
      [:start_array | _] -> :not_implemented
    end
  end

  # ---

  defp read_val(tokens), do: do_read_val(tokens, tokens)

  # Assumes tokens is right after a colon.
  defp do_read_val(all_tokens, remaining_tokens, n_processed \\ 0, obj_depth \\ 0, arr_depth \\ 0)

  # The exit condition: comma or end of input at the root level:
  defp do_read_val(tokens, [:comma | _], n_processed, 0, 0), do: Enum.take(tokens, n_processed)
  defp do_read_val(tokens, [:end_object], n_processed, 0, 0), do: Enum.take(tokens, n_processed)
  defp do_read_val(tokens, [], n_processed, 0, 0), do: Enum.take(tokens, n_processed)

  defp do_read_val(tokens, [:start_object | rest], n_processed, obj_depth, arr_depth),
    do: do_read_val(tokens, rest, n_processed + 1, obj_depth + 1, arr_depth)

  defp do_read_val(tokens, [:end_object | rest], n_processed, obj_depth, arr_depth)
       when obj_depth > 0,
       do: do_read_val(tokens, rest, n_processed + 1, obj_depth - 1, arr_depth)

  defp do_read_val(tokens, [:start_array | rest], n_processed, obj_depth, arr_depth),
    do: do_read_val(tokens, rest, n_processed + 1, obj_depth, arr_depth + 1)

  defp do_read_val(tokens, [:end_array | rest], n_processed, obj_depth, arr_depth)
       when arr_depth > 0,
       do: do_read_val(tokens, rest, n_processed + 1, obj_depth, arr_depth - 1)

  # "Skip" all other tokens:
  defp do_read_val(tokens, [_ | rest], n_processed, obj_depth, arr_depth),
    do: do_read_val(tokens, rest, n_processed + 1, obj_depth, arr_depth)

  # ---

  # Assumes tokens is right after a colon and skips until right before the next key or the end.
  defp skip_val(tokens, obj_depth \\ 0, arr_depth \\ 0)

  defp skip_val([:start_object | tokens], obj_depth, arr_depth) do
    skip_val(tokens, obj_depth + 1, arr_depth)
  end

  defp skip_val([:end_object | tokens], obj_depth, arr_depth) when obj_depth > 0 do
    skip_val(tokens, obj_depth - 1, arr_depth)
  end

  defp skip_val([:start_array | tokens], obj_depth, arr_depth) do
    skip_val(tokens, obj_depth, arr_depth + 1)
  end

  defp skip_val([:end_array | tokens], obj_depth, arr_depth) when arr_depth > 0 do
    skip_val(tokens, obj_depth, arr_depth - 1)
  end

  defp skip_val([_ | tokens], obj_depth, arr_depth) when obj_depth > 0 or arr_depth > 0 do
    skip_val(tokens, obj_depth, arr_depth)
  end

  defp skip_val([{_, _} | tokens], 0, 0), do: skip_val(tokens, 0, 0)
  defp skip_val([nil | tokens], 0, 0), do: skip_val(tokens, 0, 0)
  defp skip_val([:comma | tokens], 0, 0), do: tokens
  # The root object:
  defp skip_val([:end_object], 0, 0), do: []
  defp skip_val([], _, _), do: []
end
