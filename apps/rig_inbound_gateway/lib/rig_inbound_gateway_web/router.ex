defmodule RigInboundGatewayWeb.Router do
  use RigInboundGatewayWeb, :router

  pipeline :api do
    plug(Plug.Logger, log: :debug)
    plug(Rig.Plug.AuthHeader)
  end

  scope "/_rig", RigInboundGatewayWeb do
    pipe_through(:api)

    scope "/v1", V1 do
      scope "/connection/sse" do
        subscription_url = "/:connection_id/subscriptions"
        options(subscription_url, SubscriptionController, :handle_preflight)
        put(subscription_url, SubscriptionController, :set_subscriptions)

        # The SSE handler is implemented using Cowboy's loop handler behaviour and set
        # up using the Cowboy dispatch configuration; see the `config.exs` file.
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
