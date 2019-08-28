defmodule RigInboundGatewayWeb.HealthController do
  require Logger

  use RigInboundGatewayWeb, :controller

  @doc "Default response for health status"
  def check_health(conn, _params) do
    text(conn, "OK")
  end
end
