defmodule RIG.JWT.Claims do
  @moduledoc "Read JSON Web Tokens."

  alias Joken

  @type token :: String.t()
  @type claims :: %{optional(String.t()) => String.t()}
  @type jwt_conf :: %{alg: String.t(), key: String.t()}

  # ---

  @doc "Obtain JWT claims by parsing and validating a token."
  @spec from(token, jwt_conf) :: {:ok, claims} | {:error, String.t()}
  def from(token, jwt_conf) when byte_size(token) > 0 do
    token
    |> Joken.token()
    |> Joken.with_validation("exp", &(&1 > Joken.current_time()), "token expired")
    |> with_signer(jwt_conf)
    |> Joken.verify()
    |> Joken.get_data()
  end

  def from(thing, _), do: {:error, "not a token: #{inspect(thing)}"}

  # ---

  defp with_signer(jwt, %{alg: alg, key: key}) do
    signer =
      case alg do
        "HS" <> _ -> Joken.Signer.hs(alg, key)
        "RS" <> _ -> Joken.Signer.rs(alg, JOSE.JWK.from_pem(key))
      end

    Joken.with_signer(jwt, signer)
  end

  # ---

  @doc "Encode a signed JWT that wraps the given claims."
  @spec encode(claims, jwt_conf) :: token
  def encode(claims, jwt_conf) do
    Joken.token()
    |> Joken.with_exp()
    |> with_signer(jwt_conf)
    |> Joken.with_claims(claims)
    |> Joken.sign()
    |> Joken.get_compact()
  end
end
