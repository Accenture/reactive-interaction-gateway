defmodule RigInboundGatewayWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :rig_inbound_gateway
  use Rig.Config, []

  alias Rig.Config

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(RigInboundGatewayWeb.Router)

  @spec init(:supervisor, Keyword.t()) :: {:ok, Keyword.t()}
  def init(:supervisor, config) do
    {:ok, config} = Confex.Resolver.resolve(config)

    config = config |> Config.check_and_update_https_config()

    {:ok, config}
  end
end
