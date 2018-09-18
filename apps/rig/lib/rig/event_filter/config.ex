defmodule Rig.EventFilter.Config do
  @moduledoc """
  Configuration object for event filters.

  """

  @index_field "stable_field_index"

  @type jwt_config :: %{
          json_pointer: String.t()
        }

  @type event_config :: %{
          json_pointer: String.t()
        }

  @type field_config :: %{
          stable_field_index: non_neg_integer,
          jwt: jwt_config | nil,
          event: event_config
        }

  @type field_name :: String.t()

  @type event_type_config :: %{
          optional(field_name) => field_config
        }

  @type event_type :: String.t()

  @type t :: %{
          optional(event_type) => event_type_config
        }

  # ---

  @spec new(String.t() | nil) :: {:ok, t} | :error

  def new(nil), do: {:ok, %{}}

  def new(path_or_encoded) do
    with {:error, reason1} <- from_file(path_or_encoded),
         {:error, reason2} <- from_encoded(path_or_encoded) do
      {:error, :syntax_error, [reason1, reason2]}
    else
      {:ok, config} -> {:ok, config}
    end
  end

  # ---

  @spec from_file(String.t()) :: {:ok, t} | {:error, reason :: any}
  defp from_file(path) do
    with {:ok, content} <- File.read(path),
         {:ok, config} <- from_encoded(content) do
      {:ok, config}
    else
      {:error, _reason} = err -> err
    end
  end

  # ---

  @spec from_encoded(String.t()) :: {:ok, t} | {:error, Jason.DecodeError.t()}
  defp from_encoded(encoded) do
    Jason.decode(encoded)
  end

  # ---

  @spec for_event_type(t, String.t()) :: event_type_config
  def for_event_type(config, event_type), do: Map.get(config, event_type, %{})

  # ---

  @spec check(t) :: :ok | {:error, reason :: any}
  def check(config) do
    errors =
      for {event_type, event_type_config} <- config,
          {:error, reason} <- check_filter_config(event_type_config) do
        {event_type, reason}
      end

    if Enum.empty?(errors) do
      :ok
    else
      {:error, errors}
    end
  end

  # ---

  @spec check_filter_config(event_type_config) :: :ok | {:error, reason :: any}
  def check_filter_config(config) do
    with {:ok, indices} <- read_indices(config),
         index_set <- MapSet.new(indices),
         true <- length(indices) == MapSet.size(index_set) || :duplicate_index,
         true <- Enum.all?(indices, &(&1 >= 0)) || :negative_index,
         :ok <- check_field_configs(config) do
      :ok
    else
      {:error, :index_field_missing, fields_without_index} ->
        {:error,
         "#{@index_field} is required, but missing for fields: #{inspect(fields_without_index)}"}

      {:error, :invalid_field_config, invalid_fields} ->
        {:error, "Invalid configuation for fields: #{inspect(invalid_fields)}"}

      :duplicate_index ->
        {:error, "Duplicate index - please use a different #{@index_field} value for each field"}

      :negative_index ->
        {:error, "Negative index - please use only non-negative values for #{@index_field}"}
    end
  end

  # ---

  defp read_indices(config) do
    fields_without_index =
      for {field_name, field_config} <- config,
          not Map.has_key?(field_config, @index_field),
          do: field_name

    if Enum.empty?(fields_without_index) do
      indices =
        for {_field_name, field_config} <- config, do: Map.fetch!(field_config, @index_field)

      {:ok, indices}
    else
      {:error, :index_field_missing, fields_without_index}
    end
  end

  # ---

  defp check_field_configs(config) do
    invalid_fields =
      for {field_name, field_config} <- config,
          not field_config_valid?(field_config),
          do: field_name

    if Enum.empty?(invalid_fields) do
      :ok
    else
      {:error, :invalid_field_config, invalid_fields}
    end
  end

  # ---

  defp field_config_valid?(field_config) do
    valid_stable_field_index?(get_in(field_config, [@index_field])) and
      valid_json_pointer?(get_in(field_config, ["event", "json_pointer"]))
  end

  # ---

  defp valid_stable_field_index?(idx) when is_integer(idx) and idx >= 0, do: true
  defp valid_stable_field_index?(_), do: false

  # ---

  defp valid_json_pointer?(""), do: false
  defp valid_json_pointer?(ptr) when is_binary(ptr), do: true
  defp valid_json_pointer?(_), do: false
end
