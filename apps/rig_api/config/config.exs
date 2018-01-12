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
    port: {:system, :integer, "PORT", 4010}
  ],
  render_errors: [view: RigApi.ErrorView, accepts: ~w(json)],
  pubsub: [name: Rig.PubSub]

config :rig, RigApi.ApisController,
  rig_proxy: RigInboundGateway.Proxy

import_config "#{Mix.env}.exs"
