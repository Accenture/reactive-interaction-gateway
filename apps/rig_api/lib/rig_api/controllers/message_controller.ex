defmodule RigApi.MessageController do
  use RigApi, :controller

  alias RigOutboundGateway

  action_fallback RigApi.FallbackController

  def create(conn, message) do
    with :ok <- RigOutboundGateway.send(message) do
      send_resp(conn, :accepted, "message queued for transport")
    else
      {:error, %KeyError{key: key}} ->
        send_resp(conn, :bad_request, ~s(Bad request: expected user-ID in field "#{key}"))
      _err ->
        send_resp(conn, :bad_request, "Bad request")
    end
  end
end
