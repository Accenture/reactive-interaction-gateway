defmodule RigAuth.Jwt.Plug do
  @moduledoc """
  Provides JWT plug using Joken to verify if HTTP requests have needed authorization
  scope. This is used by RigInboundGateway REST API for manipulating with sessions/connections.
  """
  import Plug.Conn
  alias RigAuth.Jwt.Utils

  def init(options), do: options

  def call(%Plug.Conn{request_path: "/v1/users", method: "GET"} = conn, _opts) do
    process_request(conn, "rg", "getSessions")
  end

  def call(%Plug.Conn{request_path: "/v1/users/" <> _, method: "GET"} = conn, _opts) do
    process_request(conn, "rg", "getSessionConnections")
  end

  def call(%Plug.Conn{request_path: "/v1/users/" <> _, method: "DELETE"} = conn, _opts) do
    process_request(conn, "rg", "deleteConnection")
  end

  defp process_request(conn, namespace, action) do
    register_before_send(conn, fn(connection) ->
      if Utils.valid_scope?(get_req_header(connection, "authorization"), namespace, action) do
        connection
      else
        resp(connection, 403, Poison.encode!(%{msg: "Unauthorized"}))
      end
    end)
  end
end
