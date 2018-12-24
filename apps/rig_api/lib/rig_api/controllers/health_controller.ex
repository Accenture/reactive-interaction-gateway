defmodule RigApi.HealthController do
  require Logger

  use RigApi, :controller
  use PhoenixSwagger

  # Swagger documentation for endpoint GET /health
  swagger_path :check_health do
    get("/health")
    summary("Provides the RIG health status")
    description("Provides the RIG health status")

    response(200, "OK")
  end

  @doc "Default response for health status"
  def check_health(conn, _params) do
    text(conn, "OK")
  end
end
