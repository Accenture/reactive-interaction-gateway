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
      scope "/connection" do
        get("/init", ConnectionController, :init)

        get("/online", MetadataController, :is_online)

        scope "/sse" do
          subscription_url = "/:connection_id/subscriptions"
          options(subscription_url, SubscriptionController, :handle_preflight)
          put(subscription_url, SubscriptionController, :set_subscriptions)

          metadata_url = "/:connection_id/metadata"
          options(metadata_url, MetadataController, :handle_preflight)
          put(metadata_url, MetadataController, :set_metadata)

          # The SSE handler is implemented using Cowboy's loop handler behaviour and set
          # up using the Cowboy dispatch configuration; see the `config.exs` file.
        end

        scope "/ws" do
          subscription_url = "/:connection_id/subscriptions"
          options(subscription_url, SubscriptionController, :handle_preflight)
          put(subscription_url, SubscriptionController, :set_subscriptions)

          metadata_url = "/:connection_id/metadata"
          options(metadata_url, MetadataController, :handle_preflight)
          put(metadata_url, MetadataController, :set_metadata)

          # The WebSocket handler is implemented using Cowboy's loop handler behaviour and set
          # up using the Cowboy dispatch configuration; see the `config.exs` file.
        end

        # Unlike SSE & WS handlers, the LP handler is implemented using plug
        scope "/longpolling" do
          subscription_url = "/:connection_id/subscriptions"
          get("/", LongpollingController, :handle_connection)
          options(subscription_url, SubscriptionController, :handle_preflight)
          put(subscription_url, SubscriptionController, :set_subscriptions)
        end
      end

      options("/events", EventController, :handle_preflight)
      post("/events", EventController, :publish)
    end
  end

  forward("/", RigInboundGateway.ApiProxy.Plug)
end
