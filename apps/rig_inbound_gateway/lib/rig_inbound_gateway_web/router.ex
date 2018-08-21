defmodule RigInboundGatewayWeb.Router do
  use RigInboundGatewayWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(Rig.Plug.AuthHeader)
  end

  scope "/_rig", RigInboundGatewayWeb do
    pipe_through(:api)

    scope "/v1", V1 do
      scope "/connection/sse", SSE do
        get("/", Controller, :create_and_attach)
        put("/:connection_id/subscriptions/:event_type", SubscriptionController, :set)
      end

      post("/events", EventController, :publish)
    end
  end

  forward("/", RigInboundGateway.ApiProxy.Plug)
end
