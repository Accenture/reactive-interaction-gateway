defmodule RigInboundGatewayWeb.ConnCase do
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

      import RigInboundGatewayWeb.Router.Helpers
      import Joken

      # The default endpoint for testing
      @endpoint RigInboundGatewayWeb.Endpoint

      # Example mock API definition to ease testing
      @mock_api %{
        "auth" => %{
          "header_name" => "",
          "query_name" => "",
          "use_header" => false,
          "use_query" => false
        },
        "auth_type" => "none",
        "id" => "new-service",
        "name" => "new-service",
        "proxy" => %{
          "port" => 4444,
          "target_url" => "API_HOST",
          "use_env" => true
        },
        "version_data" => %{
          "default" => %{
            "endpoints" => [
              %{
                "id" => "get-movies",
                "method" => "GET",
                "not_secured" => true,
                "path" => "/myapi/movies"
              }
            ]
          }
        },
        "versioned" => false,
        "active" => true
      }

      # The key for signing JWTs:
      @jwt_secret_key Confex.fetch_env!(:rig, RigInboundGatewayWeb.ConnCase)
                      |> Keyword.fetch!(:jwt_secret_key)

      # Generation of JWT
      def generate_jwt(actions \\ []) do
        %{"scopes" => %{"rg" => %{"actions" => actions}}}
          |> token
          |> with_exp
          |> with_signer(@jwt_secret_key |> hs256)
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
