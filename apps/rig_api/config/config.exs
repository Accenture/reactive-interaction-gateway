# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :rig_api, :generators,
  context_app: :rig_outbound_gateway,
  migration: false

# --------------------------------------
# Phoenix
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig_api, RigApi.Endpoint,
  server: true,
  url: [
    host: {:system, "HOST", "localhost"}
  ],
  http: [
    port: {:system, :integer, "API_HTTP_PORT", 4010}
  ],
  https: [
    port: {:system, :integer, "API_HTTPS_PORT", 4011},
    otp_app: :rig,
    cipher_suite: :strong,
    certfile: "cert/selfsigned.pem",
    keyfile: "cert/selfsigned_key.pem",
    password: {:system, "HTTPS_KEYFILE_PASS", ""}
  ],
  render_errors: [view: RigApi.ErrorView, accepts: ~w(json)],
  pubsub: [name: Rig.PubSub],
  check_origin: false

# Always start the HTTP endpoints on application startup:
config :phoenix, :serve_endpoints, true

config :rig, RigApi.ApisController, rig_proxy: RigInboundGateway.Proxy

config :rig, :event_filter, Rig.EventFilter

config :rig_api, :phoenix_swagger,
  swagger_files: %{
    "priv/static/rig_api_swagger.json" => [
      # phoenix routes will be converted to swagger paths
      router: RigApi.Router,
      # (optional) endpoint config used to set host, port and https schemes.
      endpoint: RigApi.Endpoint
    ]
  }

import_config "#{Mix.env()}.exs"
