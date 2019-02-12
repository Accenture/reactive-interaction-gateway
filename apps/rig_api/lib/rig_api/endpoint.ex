defmodule RigApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :rig_api

  @metrics_enabled? Confex.fetch_env!(:rig_metrics, RigMetrics.Application)[:metrics_enabled?]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    # return "415 Unsupported Media Type" if not handled by any parser
    pass: [],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(Plug.Session,
    store: :cookie,
    key: "_rig_api_key",
    signing_salt: "7t9/VVWp"
  )

  # Prometheus Integration - START

  # makes the /metrics URL happen
  if @metrics_enabled? == true do
    plug(RigMetrics.MetricsPlugExporter)
  end

  # Prometheus Integration - END

  plug(RigApi.Router)

  def init(_key, config) do
    {:ok, config} = Confex.Resolver.resolve(config)

    config =
      config
      |> update_in([:https, :certfile], &resolve_path/1)
      |> update_in([:https, :keyfile], &resolve_path/1)
      |> update_in([:https, :password], &String.to_charlist/1)

    {:ok, config}
  end

  defp resolve_path(path) do
    :code.priv_dir(:rig_api)
    |> Path.join(path)
  end
end
