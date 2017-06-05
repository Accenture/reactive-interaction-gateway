defmodule Gateway.ConnCase do
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

      import Gateway.Router.Helpers
      import Joken

      # The default endpoint for testing
      @endpoint Gateway.Endpoint

      # Generation of JWT
      def generate_jwt(actions \\ []) do
        %{"scopes" => %{"rg" => %{"actions" => actions}}}
          |> token
          |> with_exp
          |> with_signer(hs256(Application.get_env(:gateway, @endpoint)[:jwt_key]))
          |> sign
          |> get_compact
      end

      # Setup for HTTP connection with JWT
      def setup_conn(scopes \\ []) do
        jwt = generate_jwt(scopes)
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", jwt)
      end
    end
  end

  setup do

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
