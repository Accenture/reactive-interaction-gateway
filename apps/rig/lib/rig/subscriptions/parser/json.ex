defmodule RIG.Subscriptions.Parser.JSON do
  @moduledoc """
  Converts input into valid subscriptions.
  """

  alias Jason

  alias Result

  alias Rig.Subscription

  # ---

  @spec from_json(json :: String.t() | nil) :: Result.t([Subscription.t()], error :: String.t())

  def from_json(""), do: {:ok, []}
  def from_json(nil), do: {:ok, []}

  def from_json(json) do
    json
    |> Jason.decode()
    |> case do
      {:error, %Jason.DecodeError{data: data, position: pos}} ->
        "failed to JSON-decode subscriptions at position #{pos} in #{inspect(data)}"
        |> Result.err()

      {:ok, decoded} when is_list(decoded) ->
        results = Enum.map(decoded, &Subscription.new/1)

        case Result.filter_and_unwrap_err(results) do
          [] ->
            results |> Result.filter_and_unwrap() |> Result.ok()

          errors ->
            error = errors |> Enum.map(&inspect/1) |> Enum.join("; ")
            Result.err("could not infer subscription from JSON: #{error}")
        end

      {:ok, decoded} ->
        "subscriptions is expected to be a JSON encoded list, got: #{inspect(decoded)}"
        |> Result.err()
    end
  end
end
