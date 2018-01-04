defmodule RigApi.Router do
  use RigApi, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :scope_auth, do: plug RigAuth.Jwt.Plug

  scope "/v1", RigApi do
    pipe_through :api
    resources "/messages", MessageController, only: [:create]
  end

  scope "/v1/users", RigApi do
    pipe_through :api
    pipe_through :scope_auth
    get "/", ChannelsController, :list_channels
    get "/:user/sessions", ChannelsController, :list_channel_sessions
    delete "/:user/sessions/:jti", ChannelsController, :disconnect_channel_session
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
