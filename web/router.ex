defmodule Gateway.Router do
  use Gateway.Web, :router
  use Terraform, terraformer: Gateway.ApiProxy.Proxy

  pipeline :api do
    plug :accepts, ["json"]
  end
  
  scope "/rg", Gateway do
    pipe_through :api
    get "/sessions", ChannelsController, :list_channels
    get "/sessions/:id", ChannelsController, :list_channel_connections
  end
  
  scope "/", Gateway do
    pipe_through :api
  end
end
