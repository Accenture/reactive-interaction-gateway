defmodule Gateway.Router do
  use Gateway.Web, :router
  use Terraform, terraformer: Gateway.Terraformers.Proxy

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Gateway do
    pipe_through :api
  end

end
