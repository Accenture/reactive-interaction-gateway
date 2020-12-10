defmodule RigInboundGatewayWeb.Router do
  use RigInboundGatewayWeb, :router

  pipeline :api do
    plug(Plug.Logger, log: :debug)
    plug(Rig.Plug.AuthHeader)
  end

  scope "/_rig", RigInboundGatewayWeb do
    pipe_through(:api)

    get("/health", HealthController, :check_health)

    scope "/v1", V1 do
      scope "/connection/sse" do
        subscription_url = "/:connection_id/subscriptions"
        options(subscription_url, SubscriptionController, :handle_preflight)
        put(subscription_url, SubscriptionController, :set_subscriptions)

        # The SSE handler is implemented using Cowboy's loop handler behaviour and set
        # up using the Cowboy dispatch configuration; see the `config.exs` file.
      end

      # Unlike SSE & WS handlers, the LP handler is implemented using plug
      scope "/connection/longpolling" do
        subscription_url = "/:connection_id/subscriptions"
        get("/", LongpollingController, :handle_connection)
        options("/", LongpollingController, :handle_preflight)
        options(subscription_url, SubscriptionController, :handle_preflight)
        put(subscription_url, SubscriptionController, :set_subscriptions)
      end

      scope "/connection/ws" do
        subscription_url = "/:connection_id/subscriptions"
        options(subscription_url, SubscriptionController, :handle_preflight)
        put(subscription_url, SubscriptionController, :set_subscriptions)

        # The WebSocket handler is implemented using Cowboy's loop handler behaviour and set
        # up using the Cowboy dispatch configuration; see the `config.exs` file.
      end

      options("/events", EventController, :handle_preflight)
      post("/events", EventController, :publish)
    end
  end

  forward("/", RigInboundGateway.ApiProxy.Plug)
end
