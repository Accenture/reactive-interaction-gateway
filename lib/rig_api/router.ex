defmodule RigApi.Router do
  use RigApi, :router
  import Phoenix.LiveDashboard.Router

  pipeline :body_parser do
    plug(Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json],
      # return "415 Unsupported Media Type" if not handled by any parser
      pass: [],
      json_decoder: Jason
    )
  end

  scope "/health", RigApi do
    pipe_through(:body_parser)
    get("/", Health, :check_health)
  end

  scope "/swagger-ui" do
    forward("/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :rig,
      swagger_file: "rig_api_swagger.json"
    )
  end

  scope "/" do
    pipe_through(:body_parser)
    live_dashboard("/dashboard")
  end

  scope "/v2", RigApi.V2 do
    scope "/apis" do
      pipe_through(:body_parser)
      get("/", APIs, :list_apis)
      post("/", APIs, :add_api)
      get("/:id", APIs, :get_api_detail)
      put("/:id", APIs, :update_api)
      delete("/:id", APIs, :deactivate_api)
    end

    scope "/messages" do
      post("/", Messages, :publish)
    end

    scope "/responses" do
      pipe_through(:body_parser)
      resources("/", Responses, only: [:create])
    end

    scope "/session-blacklist" do
      pipe_through(:body_parser)
      post("/", SessionBlacklist, :blacklist_session)
      get("/:session_id", SessionBlacklist, :check_status)
    end
  end

  scope "/v3", RigApi.V3 do
    scope "/apis" do
      pipe_through(:body_parser)
      get("/", APIs, :list_apis)
      post("/", APIs, :add_api)
      get("/:id", APIs, :get_api_detail)
      put("/:id", APIs, :update_api)
      delete("/:id", APIs, :deactivate_api)
    end

    scope "/messages" do
      post("/", Messages, :publish)
    end

    scope "/responses" do
      pipe_through(:body_parser)
      resources("/", Responses, only: [:create])
    end

    scope "/session-blacklist" do
      pipe_through(:body_parser)
      post("/", SessionBlacklist, :blacklist_session)
      get("/:session_id", SessionBlacklist, :check_status)
    end
  end

  def swagger_info do
    %{
      info: %{
        version: RIG.MixProject.project()[:version],
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
