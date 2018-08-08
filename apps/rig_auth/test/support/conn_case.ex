defmodule RigAuth.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      import Joken

      # Generation of JWT
      def generate_jwt(priv_key \\ nil) do
        jwt_secret_key = System.get_env("JWT_SECRET_KEY")
        jwt_alg = System.get_env("JWT_ALG")

        signer =
          jwt_alg
          |> case do
            "HS" <> _ = alg -> Joken.Signer.hs(alg, jwt_secret_key)
            "RS" <> _ = alg -> Joken.Signer.rs(alg, JOSE.JWK.from_pem(priv_key))
          end

        token()
        |> with_exp
        |> with_signer(signer)
        |> sign
        |> get_compact
      end
    end
  end
end
