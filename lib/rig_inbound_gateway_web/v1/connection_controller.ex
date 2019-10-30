defmodule RigInboundGatewayWeb.V1.ConnectionController do
  @moduledoc false
  use Rig.Config, [:cors]
  use RigInboundGatewayWeb, :controller
  use RigInboundGatewayWeb.Cors, [:put, :delete]

  alias Result
  alias Rig.Connection.Codec
  alias RigInboundGatewayWeb.VConnection

  require Logger

  @heartbeat_interval_ms 15_000
  @subscription_refresh_interval_ms 60_000

  @doc """
  ### Dirty Testing

      CONN_TOKEN=$(http :4000/_rig/v1/connection/init)
      http --stream ":4000/_rig/v1/connection/sse?connection_token=$CONN_TOKEN"
  """
  @spec init(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def init(%{method: "GET"} = conn, _) do
    {:ok, vconnection_pid} =
      VConnection.start_with_timeout(@heartbeat_interval_ms, @subscription_refresh_interval_ms)

    conn
    |> with_allow_origin
    |> send_resp(:ok, Codec.serialize(vconnection_pid))
  end

  @doc """
  ### Dirty Testing

      CONN_TOKEN=$(http :4000/_rig/v1/connection/init)
      http delete ":4000/_rig/v1/connection/$CONN_TOKEN/"
  """
  @spec init(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def destroy(
    %{method: "DELETE"} = conn,
    %{
      "connection_id" => connection_id
    }
  ) do
    {:ok, pid} = Codec.deserialize(connection_id)
    Process.exit(pid, :kill)

    conn
    |> with_allow_origin
    |> send_resp(:ok, "")
  end

  @doc """
  ### Dirty Testing

      CONN_TOKEN=$(http :4000/_rig/v1/connection/init)
      http delete ":4000/_rig/v1/connection/$CONN_TOKEN/socket"
  """
  @spec init(conn :: Plug.Conn.t(), params :: map) :: Plug.Conn.t()
  def destroy_connection(
    %{method: "DELETE"} = conn,
    %{
      "connection_id" => connection_id
    }
  ) do
    {:ok, pid} = Codec.deserialize(connection_id)
    send pid, :kill_connection

    conn
    |> with_allow_origin
    |> send_resp(:ok, "")
  end
end
