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

  @doc """
  Initialize the endpoint configuration.
  Invoked when the endpoint supervisor starts, allows dynamically
  configuring the endpoint from system environment or other runtime sources.
  """
  @spec init(:supervisor, Keyword.t) :: {:ok, Keyword.t}
  def init(:supervisor, config) do
    Confex.Resolver.resolve(config)
  end
end
