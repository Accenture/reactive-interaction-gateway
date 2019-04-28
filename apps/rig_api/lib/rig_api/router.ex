defmodule RigApi.Router do
  use RigApi, :router

  pipeline :api do
    plug(Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      # return "415 Unsupported Media Type" if not handled by any parser
      pass: [],
      json_decoder: Poison
    )
  end

  scope "/v1/messages", RigApi do
    post("/", MessageController, :publish)
  end

  scope "/v1", RigApi do
    pipe_through(:api)

    scope "/users" do
      get("/", ChannelsController, :list_channels)
      get("/:user/sessions", ChannelsController, :list_channel_sessions)
    end

    scope "/tokens" do
      delete("/:jti", ChannelsController, :disconnect_channel_session)
    end

    scope "/session-blacklist" do
      post("/", SessionBlacklistController, :blacklist_session)
      get("/:session_id", SessionBlacklistController, :check_status)
    end

    scope "/apis" do
      get("/", ApisController, :list_apis)
      post("/", ApisController, :add_api)
      get("/:id", ApisController, :get_api_detail)
      put("/:id", ApisController, :update_api)
      delete("/:id", ApisController, :deactivate_api)
    end
  end

  scope "/health", RigApi do
    pipe_through(:api)
    get("/", HealthController, :check_health)
  end

  scope "/swagger-ui" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :rig_api,
      swagger_file: "rig_api_swagger.json"
    )
  end

  def swagger_info do
    %{
      info: %{
        version: RigApi.Mixfile.project()[:version],
        title: "Reactive Interaction Gateway: API",
        description: """
        The Reactive Interaction Gateway provides an API that allows backend services
        to query internal state and control behavior (e.g., by blacklisting a JWT).
        The port can be configured using the `API_PORT` environment variable.

        Please note that there is no authentication or authorization on this API;
        therefore, consider exposing it to your internal network only.
        """
      },

      # Documentation for paths without Controller go here
      paths: %{
        "/metrics": %{
          get: %{
            tags: ["Metrics"],
            summary:
              "Providing metrics for monitoring in Prometheus Format (please change Scheme to http if you want to try it)",
            responses: %{
              "200": %{
                description: "Response in Prometheus format",
                content: %{
                  "text/plain": %{
                    schema: %{
                      type: "string"
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  end
end
