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
                "secured" => false,
                "path" => "/myapi/movies"
              }
            ]
          }
        },
        "versioned" => false,
        "active" => true
      }
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
