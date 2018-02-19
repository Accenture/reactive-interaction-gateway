defmodule RigApi.MessageController do
  use RigApi, :controller

  alias Plug.Conn
  alias RigOutboundGateway

  action_fallback RigApi.FallbackController

  def create(conn, message) do
    with {:content_type, ["application/json"]} <- {:content_type, Conn.get_req_header(conn, "content-type")},
         :ok <- RigOutboundGateway.send(message) do
      send_resp(conn, :accepted, "message queued for transport")
    else
      {:content_type, types} ->
        send_resp(conn, :bad_request, ~s(Bad request: expected content-type "application/json", got #{inspect types}.\n))

      {:error, %KeyError{key: key, term: term}} ->
        send_resp(conn, :bad_request, ~s(Bad request: expected user-ID in field "#{key}", got "#{inspect term}.\n))

      _err ->
        send_resp(conn, :bad_request, "Bad request")
    end
  end
end
