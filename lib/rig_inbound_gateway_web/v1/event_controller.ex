defmodule RigInboundGatewayWeb.V1.EventController do
  @moduledoc """
  Publish a CloudEvent.
  """
  require Logger
  use Rig.Config, [:cors]
  use RigInboundGatewayWeb, :controller
  use RigInboundGatewayWeb.Cors, [:post]

  alias RIG.Sources.HTTP.Handler

  @doc "Plug action to send a CloudEvent to subscribers."
  def publish(%{method: "POST"} = conn, _params) do
    conn
    |> with_allow_origin()
    |> Handler.handle_http_submission(check_authorization?: true)
  end
end
