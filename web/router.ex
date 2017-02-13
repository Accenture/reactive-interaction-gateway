defmodule Gateway.Router do
  use Gateway.Web, :router
  use Terraform, terraformer: Gateway.Terraformers.Proxy

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Gateway do
    pipe_through :api
  end
  
end
