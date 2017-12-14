# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :rig_api,
  namespace: RigApi

# Configures the endpoint
config :rig_api, RigApi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0A0ZvX7JeatvcCU9qWYWQ6M8w79WTShXtu1ks4q3mP66P59X8pQzITWCrBXzyZZT",
  render_errors: [view: RigApi.ErrorView, accepts: ~w(json)],
  pubsub: [name: RigMesh.PubSub]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :rig_api, :generators,
  context_app: :rig_outbound_gateway,
  migration: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
