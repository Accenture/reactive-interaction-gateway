defmodule RigAuth.Jwt.Utils do
  @moduledoc """
  Provides utility functions over JWT using Joken
  """
  use Rig.Config, [:secret_key]

  import Joken

  alias Plug
  alias RigAuth.Blacklist

  @type claims :: %{required(String.t()) => String.t()}

  @spec valid?(String.t()) :: boolean
  def valid?("Bearer " <> jwt) do
    jwt
    |> validate
    |> get_error == nil
  end

  def valid?(invalid_access_token) do
    %{
      error:
        "JWT=#{invalid_access_token} is missing token type. Required format is: \"Bearer token\""
    }
  end

  # ---

  @spec decode(String.t()) :: {:ok, claims} | {:error, String.t()}
  def decode(jwt) do
    jwt
    |> validate
    |> get_data
  end

  # ---

  @spec validate(String.t()) :: Joken.Token.t()
  defp validate(jwt) do
    conf = config()

    signer =
      conf.alg
      |> case do
        "HS" <> _ = alg -> Joken.Signer.hs(alg, conf.secret_key)
        "RS" <> _ = alg -> Joken.Signer.rs(alg, JOSE.JWK.from_pem(conf.secret_key))
      end

    jwt
    |> token
    |> with_validation("exp", &(&1 > current_time()), "token expired")
    |> with_signer(signer)
    |> verify
    |> check_blacklist
  end

  # ---

  @spec check_blacklist(token :: Joken.Token.t()) :: Joken.Token.t()
  defp check_blacklist(%{error: nil, claims: %{"jti" => jti}} = token) do
    case Blacklist.contains_jti?(Blacklist, jti) do
      true -> %{token | error: "JWT with JTI=#{jti} is blacklisted"}
      false -> token
    end
  end

  defp check_blacklist(token), do: token
end
