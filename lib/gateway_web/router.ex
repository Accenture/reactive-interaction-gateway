defmodule GatewayWeb.Router do
  use GatewayWeb, :router
  use Terraform, terraformer: Gateway.ApiProxy.Proxy

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :scope_auth, do: plug Gateway.Utils.JwtPlug

  scope "/rg", GatewayWeb do
    pipe_through :api
    pipe_through :scope_auth
    get "/sessions", Presence.Controller, :list_channels
    get "/sessions/:id", Presence.Controller, :list_channel_connections
    delete "/connections/:jti", Presence.Controller, :disconnect_channel_connection
  end

  scope "/", GatewayWeb do
    pipe_through :api
  end
end
