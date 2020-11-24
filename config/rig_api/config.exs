# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :rig, :generators,
  context_app: :rig_outbound_gateway,
  migration: false

# --------------------------------------
# Phoenix
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

cowboy_options = [
  # Headers configuration
  max_header_value_length: 16_384
]

config :rig, RigApi.Endpoint,
  live_view: [signing_salt: "Mb9ilmLoxae6ANcIXTap3vdzAZuZceBi"],
  secret_key_base: "some_secret",
  server: true,
  url: [
    host: {:system, "HOST", "localhost"}
  ],
  http: [
    port: {:system, :integer, "API_HTTP_PORT", 4010},
    protocol_options: cowboy_options
  ],
  https: [
    port: {:system, :integer, "API_HTTPS_PORT", 4011},
    otp_app: :rig,
    cipher_suite: :strong,
    certfile: {:system, "HTTPS_CERTFILE", ""},
    keyfile: {:system, "HTTPS_KEYFILE", ""},
    password: {:system, "HTTPS_KEYFILE_PASS", ""},
    protocol_options: cowboy_options
  ],
  render_errors: [view: RigApi.ErrorView, accepts: ~w(json)],
  pubsub_server: Rig.PubSub,
  check_origin: false

# Always start the HTTP endpoints on application startup:
config :phoenix, :serve_endpoints, true

config :rig, RigApi.V1.APIs, rig_proxy: RigInboundGateway.Proxy
config :rig, RigApi.V2.APIs, rig_proxy: RigInboundGateway.Proxy
config :rig, RigApi.V3.APIs, rig_proxy: RigInboundGateway.Proxy

config :rig, :event_filter, Rig.EventFilter

config :rig, :phoenix_swagger,
  swagger_files: %{
    "priv/static/rig_api_swagger.json" => [
      # phoenix routes will be converted to swagger paths
      router: RigApi.Router,
      # (optional) endpoint config used to set host, port and https schemes.
      endpoint: RigApi.Endpoint
    ]
  }

import_config "#{Mix.env()}.exs"
