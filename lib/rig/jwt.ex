defmodule RIG.JWT do
  @moduledoc "JSON Web Token handling."
  defmodule DecodeError do
    defexception [:cause]

    def message(%__MODULE__{cause: cause}) when byte_size(cause) > 0,
      do: "could not decode JWT: #{cause}"

    def message(%__MODULE__{cause: cause}),
      do: "could not decode JWT: #{Exception.message(cause)}"
  end

  use Rig.Config, [:jwt_conf]

  alias __MODULE__.Claims
  alias __MODULE__.HttpCredentials

  alias RIG.Session

  @type token :: String.t()
  @type claims :: %{optional(String.t()) => String.t()}
  @type validation_result :: {:ok, claims} | {:error, %DecodeError{}}
  @type claims_and_errors :: [validation_result]
  @type http_header_value :: String.t()
  @type http_header :: {http_header_name :: String.t(), http_header_value}
  @type http_headers :: [http_header]
  @type jwt_conf :: %{alg: String.t(), key: String.t()}

  @typedoc "Turns claims into errors for blacklisted JWTs."
  @type ensure_not_blacklisted :: (claims -> validation_result)

  @doc """
  Find JWT claims in one or more HTTP headers.

  All "Authorization" headers are considered. A single header may contain one or more
  credentials. Only "Bearer"-type (scheme) credentials are interpreted as JSON Web
  Tokens. Each of those JWTs is validated using their signature. The result contains
  JWT claims for successfully validated tokens and errors where the validation failed.
  """
  @callback parse_http_header(http_header_value | http_headers, jwt_conf, ensure_not_blacklisted) ::
              claims_and_errors
  def parse_http_header(
        http_headers,
        jwt_conf \\ config().jwt_conf,
        ensure_not_blacklisted \\ &ensure_not_blacklisted/1
      )

  def parse_http_header(http_headers, jwt_conf, ensure_not_blacklisted)
      when is_list(http_headers) do
    for {"authorization", value} <- http_headers,
        validation_result <- parse_http_header(value, jwt_conf, ensure_not_blacklisted),
        do: validation_result
  end

  def parse_http_header(header_value, jwt_conf, ensure_not_blacklisted)
      when byte_size(header_value) > 0 do
    for {:bearer, token} <- HttpCredentials.from(header_value) do
      parse_token(token, jwt_conf, ensure_not_blacklisted)
    end
  end

  def parse_http_header(_, _, _), do: []

  # ---

  @doc """
  Extract claims from a given encoded JWT.
  """
  @callback parse_token(token, jwt_conf, ensure_not_blacklisted) :: validation_result
  def parse_token(
        token,
        jwt_conf \\ config().jwt_conf,
        ensure_not_blacklisted \\ &ensure_not_blacklisted/1
      )

  def parse_token(token, jwt_conf, ensure_not_blacklisted) do
    token
    |> Claims.from(jwt_conf)
    |> Result.and_then(fn claims -> ensure_not_blacklisted.(claims) end)
    |> Result.map_err(&%DecodeError{cause: &1})
  end

  # ---

  @doc "Checks an encoded JWT for validity."
  @callback valid?(token, jwt_conf, ensure_not_blacklisted) :: boolean()
  def valid?(
        token,
        jwt_conf \\ config().jwt_conf,
        ensure_not_blacklisted \\ &ensure_not_blacklisted/1
      )

  def valid?(token, jwt_conf, ensure_not_blacklisted) do
    token
    |> parse_token(jwt_conf, ensure_not_blacklisted)
    |> case do
      {:ok, _} -> true
      _ -> false
    end
  end

  # ---

  defp ensure_not_blacklisted(%{"jti" => jti} = claims) do
    if Session.blacklisted?(jti) do
      {:error, "Ignoring blacklisted JWT with ID #{inspect(jti)}."}
    else
      {:ok, claims}
    end
  end

  defp ensure_not_blacklisted(claims), do: {:ok, claims}

  # ---

  @spec encode(claims, jwt_conf) :: token
  def encode(claims, jwt_conf \\ config().jwt_conf)

  defdelegate encode(claims, jwt_conf), to: Claims
end
