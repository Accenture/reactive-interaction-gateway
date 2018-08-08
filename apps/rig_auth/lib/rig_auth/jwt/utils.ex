defmodule RigAuth.Jwt.Utils do
  @moduledoc """
  Provides utility functions over JWT using Joken
  """
  use Rig.Config, [:secret_key]
  import Joken

  @type claim_map :: %{required(String.t) => String.t}

  @spec valid?(String.t) :: boolean
  def valid?(jwt) do
    jwt
    |> validate
    |> get_error == nil
  end

  @spec decode(String.t) :: {:ok, map} | {:error, String.t}
  def decode(jwt) do
    jwt
    |> validate
    |> get_data
  end

  @spec validate(String.t) :: map
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
  end
end
