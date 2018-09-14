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
        post(subscription_url, SubscriptionController, :create_subscription)

        get("/", SSE, :create_and_attach)
      end

      scope "/connection/ws" do
        # /connection/ws is configured in the Phoenix/Cowboy dispatch configuration

        subscription_url = "/:connection_id/subscriptions"
        options(subscription_url, SubscriptionController, :handle_preflight)
        post(subscription_url, SubscriptionController, :create_subscription)
      end

      options("/events", EventController, :handle_preflight)
      post("/events", EventController, :publish)
    end
  end

  forward("/", RigInboundGateway.ApiProxy.Plug)
end
