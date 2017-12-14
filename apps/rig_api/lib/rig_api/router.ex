defmodule RigApi.Router do
  use RigApi, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/v1", RigApi do
    pipe_through :api
    resources "/messages", MessageController, only: [:create]
  end
end
