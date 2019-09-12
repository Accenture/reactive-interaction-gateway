defmodule RigInboundGatewayWeb.V1.MetadataController do
  use RigInboundGatewayWeb, :controller

  alias Result

  alias RIG.AuthorizationCheck.Request
  alias RIG.AuthorizationCheck.Subscription, as: SubscriptionAuthZ
  alias Rig.Connection
  alias RIG.JWT
  alias RIG.Plug.BodyReader
  alias RIG.Session
  alias Rig.Subscription
  alias RIG.Subscriptions

  require Logger

  @spec set_metadata( conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def set_metadata(
      %{method: "PUT"} = conn,
      %{
         "connection_id" => connection_id
      }
  ) do
    IO.puts "REACHED SET METADATA"
    IO.puts(BodyReader.read_full_body(conn) |> elem(1))

    send_resp(conn, :no_content, "")
  end
end
