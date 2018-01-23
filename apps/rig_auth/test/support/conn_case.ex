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

      # The key for signing JWTs:
      @jwt_secret_key Confex.fetch_env!(:rig, RigAuth.ConnCase)
                      |> Keyword.fetch!(:jwt_secret_key)

      # Generation of JWT
      def generate_jwt do
        token()
        |> with_exp
        |> with_signer(@jwt_secret_key |> hs256)
        |> sign
        |> get_compact
      end
    end
  end
end
