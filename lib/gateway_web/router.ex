defmodule GatewayWeb.Router do
  use GatewayWeb, :router

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

  scope "/apis", GatewayWeb do
    pipe_through :api
    get "/", Proxy.Controller, :list_apis
    post "/", Proxy.Controller, :add_api
    # get "/:id", Proxy.Controller, :api_detail
    put "/:id", Proxy.Controller, :update_api
    delete "/:id", Proxy.Controller, :delete_api
  end

  forward "/", Gateway.ApiProxy.Plug
end
