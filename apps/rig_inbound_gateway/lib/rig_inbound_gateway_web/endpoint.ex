defmodule RigInboundGatewayWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :rig_inbound_gateway

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(RigInboundGatewayWeb.Router)

  @spec init(:supervisor, Keyword.t()) :: {:ok, Keyword.t()}
  def init(:supervisor, config) do
    {:ok, config} = Confex.Resolver.resolve(config)

    config =
      config
      |> update_in([:https, :certfile], &resolve_path/1)
      |> update_in([:https, :keyfile], &resolve_path/1)
      |> update_in([:https, :password], &String.to_charlist/1)

    {:ok, config}
  end

  defp resolve_path(path) do
    :code.priv_dir(:rig_inbound_gateway)
    |> Path.join(path)
  end
end
