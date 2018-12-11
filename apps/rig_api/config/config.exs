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
  url: [
    host: {:system, "HOST", "localhost"}
  ],
  http: [
    port: {:system, :integer, "API_PORT", 4010}
  ],
  render_errors: [view: RigApi.ErrorView, accepts: ~w(json)],
  pubsub: [name: Rig.PubSub]

# Always start the HTTP endpoints on application startup:
config :phoenix, :serve_endpoints, true

config :rig, RigApi.ApisController, rig_proxy: RigInboundGateway.Proxy

config :rig, :event_filter, Rig.EventFilter

config :rig_api, :phoenix_swagger,
  swagger_files: %{
    "priv/static/rig_api_swagger.json" => [
      router: RigApi.Router,     # phoenix routes will be converted to swagger paths
      endpoint: RigApi.Endpoint  # (optional) endpoint config used to set host, port and https schemes.
    ]
  }

import_config "#{Mix.env()}.exs"
