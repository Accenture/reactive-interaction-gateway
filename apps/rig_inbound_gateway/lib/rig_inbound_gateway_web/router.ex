defmodule RigInboundGatewayWeb.Router do
  use RigInboundGatewayWeb, :router

  pipeline :api do
    plug(Plug.Logger, log: :debug)
    plug(:accepts, ~w(json event-stream))
    plug(Rig.Plug.AuthHeader)
  end

  scope "/_rig", RigInboundGatewayWeb do
    pipe_through(:api)

    scope "/v1", V1 do
      scope "/connection/sse" do
        subscription_url = "/:connection_id/subscriptions"
        options(subscription_url, SubscriptionController, :handle_preflight)
        put(subscription_url, SubscriptionController, :set_subscriptions)

        get("/", SSE, :create_and_attach)
      end

      scope "/connection/ws" do
        # /connection/ws is configured in the Phoenix/Cowboy dispatch configuration

        subscription_url = "/:connection_id/subscriptions"
        options(subscription_url, SubscriptionController, :handle_preflight)
        put(subscription_url, SubscriptionController, :set_subscriptions)
      end

      options("/events", EventController, :handle_preflight)
      post("/events", EventController, :publish)
    end
  end

  forward("/", RigInboundGateway.ApiProxy.Plug)
end
