defmodule RigApi.V2.ConnectionController do
  @moduledoc """
  Exposes functionality to close individual connections.
  Used in debugging.
  """

  use Rig.Config, [:cors]
  use RigInboundGatewayWeb, :controller
  use RigInboundGatewayWeb.Cors, [:delete]

  alias Rig.Connection.Codec

  @doc """
  ### Dirty Testing

      CONN_TOKEN=$(http :4000/_rig/v1/connection/init)
      http delete ":4010/v2/connection/$CONN_TOKEN/socket"
  """
  @spec destroy_connection(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def destroy_connection(
        %{method: "DELETE"} = conn,
        %{
          "connection_id" => connection_id
        }
      ) do
    {:ok, pid} = Codec.deserialize(connection_id)
    send(pid, :kill_connection)

    conn
    |> with_allow_origin
    |> send_resp(:ok, "")
  end
end
