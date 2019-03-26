defmodule RIG.Subscriptions.Parser.JSON do
  @moduledoc """
  Converts input into valid subscriptions.
  """
  defmodule DecodeError do
    defexception [:json, :error]

    def message(e),
      do: "could not decode subscriptions: #{e.error} when parsing JSON: #{inspect(e.json)}"
  end

  defmodule ParseError do
    defexception [:cause]

    def message(error),
      do: "could not parse subscription from JSON: #{Exception.message(error.cause)}"
  end

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
        %DecodeError{error: "invalid JSON encoding at position #{pos}", json: data}
        |> Result.err()

      {:ok, decoded} when is_list(decoded) ->
        parse_subscriptions(decoded)

      {:ok, _} ->
        %DecodeError{
          error: "subscriptions is expected to be a JSON encoded list",
          json: json
        }
        |> Result.err()
    end
  end

  defp parse_subscriptions(decoded) when is_list(decoded) do
    decoded
    |> Enum.map(&Subscription.new!/1)
    |> Result.ok()
  rescue
    error in Subscription.ValidationError ->
      Result.err(%ParseError{cause: error})
  end
end
