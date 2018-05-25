defmodule RigApi.Router do
  use RigApi, :router

  pipeline :api do
    plug :put_format, :json
  end

  scope "/v1", RigApi do
    pipe_through :api
    resources "/messages", MessageController, only: [:create]
  end

  scope "/v1/users", RigApi do
    pipe_through :api
    get "/", ChannelsController, :list_channels
    get "/:user/sessions", ChannelsController, :list_channel_sessions
  end

  scope "/v1/sessions", RigApi do
    pipe_through :api
    delete "/:jti", ChannelsController, :disconnect_channel_session
  end

  scope "/v1/apis", RigApi do
    pipe_through :api
    get "/", ApisController, :list_apis
    post "/", ApisController, :add_api
    get "/:id", ApisController, :get_api_detail
    put "/:id", ApisController, :update_api
    delete "/:id", ApisController, :deactivate_api
  end
end
