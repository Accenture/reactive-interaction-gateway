defmodule RigInboundGatewayWeb.V1.EventController do
  @moduledoc """
  Publish a CloudEvent.
  """
  require Logger
  use Rig.Config, [:cors]

  use RigInboundGatewayWeb, :controller

  alias RIG.Sources.HTTP.Handler

  @doc false
  def handle_preflight(%{method: "OPTIONS"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> put_resp_header("access-control-allow-methods", "POST")
    |> put_resp_header("access-control-allow-headers", "content-type")
    |> send_resp(:no_content, "")
  end

  # ---

  defp with_allow_origin(conn) do
    %{cors: origins} = config()
    put_resp_header(conn, "access-control-allow-origin", origins)
  end

  # ---

  @doc "Plug action to send a CloudEvent to subscribers."
  def publish(%{method: "POST"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> Plug.Conn.fetch_query_params()
    |> Handler.handle_http_submission(check_authorization?: true)
  end
end
