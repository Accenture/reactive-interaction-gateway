defmodule RIG.Subscriptions.Parser.JSON do
  @moduledoc """
  Converts input into valid subscriptions.
  """

  alias Jason

  alias Result

  alias Rig.Subscription

  @spec from_json(json :: String.t()) :: [Result.t(Subscription.t(), any)]
  def from_json(json) do
    json
    |> Jason.decode()
    |> case do
      {:error, _} = error ->
        [error]

      {:ok, decoded} when is_list(decoded) ->
        Enum.map(decoded, &Subscription.new/1)

      {:ok, decoded} ->
        [error: "subscriptions is expected to be a JSON encoded list, got: #{inspect(decoded)}"]
    end
  end
end
