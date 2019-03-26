defmodule RIG.Subscriptions.Parser.JWT do
  @moduledoc """
  Create subscriptions based on JWT and extractor file
  """

  alias Result

  alias Rig.Subscription

  # ---

  @spec from_jwt_claims(map, map) :: Result.t([Subscription.t()], error :: String.t())

  def from_jwt_claims(claims, extractor_map) when is_map(claims) and is_map(extractor_map) do
    results =
      for {event_type, type_config} <- extractor_map do
        case constraints_for_event_type(claims, type_config) do
          [map] when map == %{} ->
            nil

          constraints ->
            Subscription.new(%{
              event_type: event_type,
              constraints: constraints
            })
        end
      end
      |> Enum.reject(&is_nil/1)

    case Result.filter_and_unwrap_err(results) do
      [] ->
        results |> Result.filter_and_unwrap() |> Result.ok()

      errors ->
        error = errors |> Enum.map(&inspect/1) |> Enum.join("; ")
        Result.err("could not infer subscription from JWT: #{error}")
    end
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
    |> List.wrap()
  end

  # ---

  defp jwt_pointer(field_config)
  defp jwt_pointer(%{"jwt" => %{"json_pointer" => jwt_pointer}}), do: {:ok, jwt_pointer}
  defp jwt_pointer(_), do: :not_found
end
