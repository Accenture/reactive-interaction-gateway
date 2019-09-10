defmodule RigApi.Health do
  @moduledoc "Controller for the health endpoint."
  require Logger

  use RigApi, :controller
  use PhoenixSwagger

  swagger_path :check_health do
    get("/health")
    summary("Check if RIG is online.")
    response(200, "OK")
  end

  @doc "Default response for health status"
  def check_health(conn, _params) do
    text(conn, "OK")
  end
end
