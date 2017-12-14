defmodule RigInboundGateway.Utils.JwtPlug do
  @moduledoc """
  Provides JWT plug using Joken to verify if HTTP requests have needed authorization
  scope. This is used by RigInboundGateway REST API for manipulating with sessions/connections.
  """
  import Plug.Conn
  alias RigInboundGateway.Utils.Jwt

  def init(options), do: options

  def call(conn = %Plug.Conn{request_path: "/rg/sessions", method: "GET"}, _opts) do
    process_request(conn, "rg", "getSessions")
  end

  def call(conn = %Plug.Conn{request_path: "/rg/sessions/" <> _, method: "GET"}, _opts) do
    process_request(conn, "rg", "getSessionConnections")
  end

  def call(conn = %Plug.Conn{request_path: "/rg/connections/" <> _, method: "DELETE"}, _opts) do
    process_request(conn, "rg", "deleteConnection")
  end

  defp process_request(conn, namespace, action) do
    register_before_send(conn, fn(connection) ->
      if Jwt.valid_scope?(get_req_header(connection, "authorization"), namespace, action) do
        connection
      else
        resp(connection, 403, Poison.encode!(%{msg: "Unauthorized"}))
      end
    end)
  end
end
