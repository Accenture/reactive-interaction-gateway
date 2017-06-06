defmodule Gateway.Router do
  use Gateway.Web, :router
  use Terraform, terraformer: Gateway.ApiProxy.Proxy

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :scope_auth, do: plug Gateway.Utils.JwtPlug

  scope "/rg", Gateway do
    pipe_through :api
    pipe_through :scope_auth
    get "/sessions", ChannelsController, :list_channels
    get "/sessions/:id", ChannelsController, :list_channel_connections
    delete "/connections/:jti", ChannelsController, :disconnect_channel_connection
  end

  scope "/", Gateway do
    pipe_through :api
  end
end
