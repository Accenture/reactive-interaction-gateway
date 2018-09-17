defmodule Rig.EventFilter.Config do
  @moduledoc """
  Configuration object for event filters.

  """

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
    with {:error, _} <- from_file(path_or_encoded),
         {:error, _} <- from_encoded(path_or_encoded) do
      {:error, :syntax_error}
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
end
