defmodule RIG.JWT do
  @moduledoc "JSON Web Token handling."

  alias __MODULE__.Claims
  alias __MODULE__.HttpCredentials

  alias RigAuth.Blacklist

  @type token :: String.t()
  @type claims :: %{optional(String.t()) => String.t()}
  @type validation_result :: {:ok, claims} | {:error, any}
  @type claims_and_errors :: [validation_result]
  @type http_header_value :: String.t()
  @type http_header :: {http_header_name :: String.t(), http_header_value}
  @type http_headers :: [http_header]
  @type jwt_conf :: %{alg: String.t(), key: String.t()}

  @typedoc "Turns claims into errors for blacklisted JWTs."
  @type redact_blacklisted :: (validation_result -> validation_result)

  @jwt_conf Confex.fetch_env!(:rig, :jwt_conf)

  @doc """
  Find JWT claims in one or more HTTP headers.

  All "Authorization" headers are considered. A single header may contain one or more
  credentials. Only "Bearer"-type (scheme) credentials are considered are interpreted
  as JSON Web Tokens. Each of those JWTs is validated using their signature. The
  result contains JWT claims for successfully validated tokens and errors where the
  validation failed.
  """
  @callback parse_http_header(http_header_value | http_headers, jwt_conf, redact_blacklisted) ::
              claims_and_errors
  def parse_http_header(
        http_headers,
        jwt_conf \\ @jwt_conf,
        redact_blacklisted \\ &redact_blacklisted/1
      )

  def parse_http_header(http_headers, jwt_conf, redact_blacklisted) when is_list(http_headers) do
    for {"authorization", value} <- http_headers,
        validation_result <- parse_http_header(value, jwt_conf, redact_blacklisted),
        do: validation_result
  end

  def parse_http_header(header_value, jwt_conf, redact_blacklisted)
      when byte_size(header_value) > 0 do
    for {:bearer, token} <- HttpCredentials.from(header_value) do
      parse_token(token, jwt_conf, redact_blacklisted)
    end
  end

  def parse_http_header(_, _, _), do: []

  # ---

  @doc """
  Extract claims from a given encoded JWT.
  """
  @callback parse_token(token, jwt_conf, redact_blacklisted) :: validation_result
  def parse_token(
        token,
        jwt_conf \\ @jwt_conf,
        redact_blacklisted \\ &redact_blacklisted/1
      )

  def parse_token(token, jwt_conf, redact_blacklisted) do
    token
    |> Claims.from(jwt_conf)
    |> redact_blacklisted.()
  end

  # ---

  @spec redact_blacklisted(validation_result) :: validation_result

  defp redact_blacklisted({:ok, %{"jti" => jti} = claims}) do
    if Blacklist.contains_jti?(Blacklist, jti) do
      {:error, "Ignoring blacklisted JWT with ID #{jti}."}
    else
      {:ok, claims}
    end
  end

  defp redact_blacklisted(result), do: result

  # ---

  @spec encode(claims, jwt_conf) :: token
  def encode(claims, jwt_conf \\ @jwt_conf)

  defdelegate encode(claims, jwt_conf), to: Claims
end
