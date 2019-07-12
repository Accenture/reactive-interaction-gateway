defmodule RigAuth.Jwt.TokenUtils do
  use Joken.Config, default_signer: nil # no default signer. Do not set as that will break Jwks retrieval

  use Rig.Config, [:secret_key, :rotation_flag, :jwks_endpoint]

  @conf_var config()

  def config_retrieval do
    @conf_var
  end

  if conf_var.rotation_flag do
    # This hook implements a before_verify callback that checks whether it has a signer configuration
    # cached. If it does not, it tries to fetch it from the jwks_url.
    add_hook(JokenJwks, jwks_url: conf_var.jwks_endpoint)
  end

  def retrieve_signer do
    conf = config()

    case conf.alg do
      "HS256" <> _ = alg -> Joken.Signer.create(alg, conf.secret_key)
      "RS256" <> _ = alg -> Joken.Signer.create(alg, JOSE.JWK.from_pem(conf.secret_key))
    end
  end

  def token_config do
    %{}
    |> add_claim("my_key", fn -> "My custom claim" end, &(&1 == "My custom claim"))
  end

  @spec valid?(String.t()) :: boolean
  def valid?("Bearer " <> jwt) do
    jwt
    |> verify_and_validate(jwt)
    |> get_error == nil
  end

  def valid?(invalid_access_token) do
    %{
      error:
        "JWT=#{invalid_access_token} is missing token type. Required format is: \"Bearer token\""
    }
  end

end

# {:ok, token} = RigAuth.Jwt.TokenUtils.generate_and_sign()

# {:ok, claims} = RigAuth.Jwt.TokenUtils.verify_and_validate(token)

# claims = %{"my_key" => "My custom claim"}
