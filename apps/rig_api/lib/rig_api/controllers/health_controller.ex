defmodule RigApi.HealthController do
    require Logger
  
    use RigApi, :controller
  
    @doc "Default response for health status"
    def check_health(conn, _params) do
      text(conn, "OK")
    end
  end