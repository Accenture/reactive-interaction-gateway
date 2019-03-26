defmodule RIG.Subscriptions do
  @moduledoc """
  Event subscriptions.
  """

  alias Result

  alias Rig.EventFilter.Config, as: ExtractorConfig
  alias RIG.JWT
  alias Rig.Subscription

  alias __MODULE__.Parser

  @type claims :: %{optional(String.t()) => String.t()}

  # ---

  defdelegate from_json(json), to: Parser.JSON

  # ---

  @spec from_jwt_claims(claims) :: Result.t([Subscription.t()], error :: String.t())
  def from_jwt_claims(
        claims,
        extractor_path_or_json \\ Confex.fetch_env!(:rig, :extractor_path_or_json)
      )

  def from_jwt_claims(claims, extractor_path_or_json) do
    {:ok, extractor_map} = ExtractorConfig.new(extractor_path_or_json)
    Parser.JWT.from_jwt_claims(claims, extractor_map)
  end

  # ---

  @spec from_token(token :: JWT.token()) :: Result.t([Subscription.t()], error :: String.t())
  def from_token(token)

  def from_token(nil), do: Result.ok([])
  def from_token(""), do: Result.ok([])

  def from_token(token) do
    token
    |> JWT.parse_token()
    |> Result.and_then(&from_jwt_claims/1)
  end
end
