defmodule RigApi.Endpoint do
  use Phoenix.Endpoint, otp_app: :rig_api
  use Rig.Config

  alias Rig.Config

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Logger)

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
  plug(RigMetrics.MetricsPlugExporter)
  # Prometheus Integration - END

  plug(RigApi.Router)

  def init(_key, config) do
    {:ok, config} = Confex.Resolver.resolve(config)

    config = config |> Config.check_and_update_https_config()

    {:ok, config}
  end
end
