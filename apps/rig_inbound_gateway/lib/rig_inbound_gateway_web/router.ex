defmodule RigInboundGatewayWeb.Router do
  use RigInboundGatewayWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  forward "/", RigInboundGateway.ApiProxy.Plug
end
