defmodule RIG.Subscriptions do
  @moduledoc """
  Event subscriptions.
  """
  defmodule Error do
    defexception [:cause]

    def message(%__MODULE__{cause: cause}) when byte_size(cause) > 0,
      do: "could not parse subscriptions: #{cause}"

    def message(%__MODULE__{cause: cause}),
      do: "could not parse subscriptions: #{Exception.message(cause)}"
  end

  use Rig.Config, [:jwt_conf, :extractor_path_or_json]

  alias Result

  alias Rig.EventFilter.Config, as: ExtractorConfig
  alias RIG.JWT
  alias Rig.Subscription

  alias __MODULE__.Parser

  @type claims :: %{optional(String.t()) => String.t()}
  @type jwt_conf :: %{alg: String.t(), key: String.t()}

  # ---

  @spec from_json(json :: String.t() | nil) :: Result.t([Subscription.t()], %Error{})
  def from_json(json) do
    json
    |> Parser.JSON.from_json()
    |> Result.map_err(&%Error{cause: &1})
  end

  # ---

  @spec from_jwt_claims(claims) :: Result.t([Subscription.t()], %Error{})
  def from_jwt_claims(
        claims,
        extractor_path_or_json \\ config().extractor_path_or_json
      )

  def from_jwt_claims(claims, extractor_path_or_json) do
    {:ok, extractor_map} = ExtractorConfig.new(extractor_path_or_json)

    Parser.JWT.from_jwt_claims(claims, extractor_map)
    |> Result.map_err(&%Error{cause: &1})
  end

  # ---

  @spec from_token(token :: JWT.token(), jwt_conf) :: Result.t([Subscription.t()], %Error{})
  def from_token(token, jwt_conf \\ config().jwt_conf)

  def from_token(nil, _jwt_conf), do: Result.ok([])
  def from_token("", _jwt_conf), do: Result.ok([])

  def from_token(token, jwt_conf) do
    token
    |> JWT.parse_token(jwt_conf)
    |> Result.map_err(&%Error{cause: &1})
    |> Result.and_then(&from_jwt_claims/1)
  end
end
