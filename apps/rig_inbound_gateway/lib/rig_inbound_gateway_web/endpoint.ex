defmodule RigInboundGatewayWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :rig_inbound_gateway
  require Logger

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

    config = config |> check_and_update_https_config

    {:ok, config}
  end

  @spec check_and_update_https_config(Keyword.t()) :: Keyword.t()
  defp check_and_update_https_config(config) do
    certfile =
      config
      |> Keyword.get(:https)
      |> Keyword.get(:certfile)

    if(certfile === "") do
      Logger.warn("No HTTPS_CERTFILE environment variable provided. Disabling HTTPS...")

      # DISABLE HTTPS
      config
      |> update_in([:https], &disable_https/1)
    else
      # UPDATE https_config to add priv/ folder to path
      config
      |> update_in([:https, :certfile], &resolve_path/1)
      |> update_in([:https, :keyfile], &resolve_path/1)
      |> update_in([:https, :password], &String.to_charlist/1)
    end
  end

  defp resolve_path(path) do
    :code.priv_dir(:rig_inbound_gateway)
    |> Path.join(path)
  end

  defp disable_https(_) do
    false
  end
end
