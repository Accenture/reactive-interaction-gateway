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

  @jwt_conf Confex.fetch_env!(:rig, :jwt_conf)

  # ---

  defdelegate from_json(json), to: Parser.JSON

  # ---

  @spec from_jwt_claims(claims) :: [Result.t(Subscription.t(), any)]
  def from_jwt_claims(
        claims,
        extractor_path_or_json \\ Confex.fetch_env!(:rig, :extractor_path_or_json)
      )

  def from_jwt_claims(claims, extractor_path_or_json) do
    {:ok, extractor_map} = ExtractorConfig.new(extractor_path_or_json)
    Parser.JWT.from_jwt_claims(claims, extractor_map)
  end

  # ---

  @spec from_token(token :: JWT.token()) :: [Result.t(Subscription.t(), any)]
  def from_token(token, jwt_conf \\ @jwt_conf)

  def from_token(nil, _jwt_conf), do: []
  def from_token("", _jwt_conf), do: []

  def from_token(token, jwt_conf) do
    token
    |> JWT.parse_token(jwt_conf)
    |> Result.map(&from_jwt_claims/1)
    |> case do
      {:ok, subscription_results} -> subscription_results
      {:error, jwt_error} -> [{:error, "JWT: #{jwt_error}"}]
    end
  end
end
