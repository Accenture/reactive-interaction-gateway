defmodule RIG.Subscriptions.Parser.JWT do
  @moduledoc """
  Create subscriptions based on JWT and extractor file
  """
  defmodule Error do
    defexception [:cause]

    def message(error),
      do: "could not infer subscription from JWT: #{Exception.message(error.cause)}"
  end

  alias Result

  alias Rig.Subscription

  # ---

  @spec from_jwt_claims(map, map) :: Result.t([Subscription.t()], error :: String.t())

  def from_jwt_claims(claims, extractor_map) when is_map(claims) and is_map(extractor_map) do
    for {event_type, type_config} <- extractor_map do
      case constraints_for_event_type(claims, type_config) do
        [map] when map == %{} ->
          nil

        constraints ->
          Subscription.new!(%{
            event_type: event_type,
            constraints: constraints
          })
      end
    end
    |> Enum.reject(&is_nil/1)
    |> Result.ok()
  rescue
    error in Subscription.ValidationError ->
      Result.err(%Error{cause: error})
  end

  # ---

  # JWT based constraints are currently always a logical conjunction,
  # which is represented as a single map with one entry per field.
  defp constraints_for_event_type(claims, event_type_config) do
    for {field_name, field_config} <- event_type_config do
      with {:ok, jwt_pointer} <- jwt_pointer(field_config),
           {:ok, value} <- JSONPointer.get(claims, jwt_pointer) do
        {:ok, {field_name, value}}
      else
        err -> Result.err(err)
      end
    end
    |> Result.filter_and_unwrap()
    |> Enum.into(%{})
    |> Enum.map(fn {key, value} ->
         cond do
           is_list(value) -> Enum.map(value, fn element -> %{key => element} end)
           is_bitstring(value) -> [%{key => value}]
         end
       end)
    |> Enum.flat_map(& &1)
    |> List.wrap()
  end

  # ---

  defp jwt_pointer(field_config)
  defp jwt_pointer(%{"jwt" => %{"json_pointer" => jwt_pointer}}), do: {:ok, jwt_pointer}
  defp jwt_pointer(_), do: :not_found
end
