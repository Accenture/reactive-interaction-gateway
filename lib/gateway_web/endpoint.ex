defmodule GatewayWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :gateway

  socket "/socket", GatewayWeb.Presence.Socket

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug GatewayWeb.Router
end
