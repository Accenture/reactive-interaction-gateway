# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :gateway, Gateway.Endpoint,
  url: [host: "localhost"],
  jwt_key: "supersecrettoken",
  secret_key_base: "qjiJFnMIbw3Bs2lbM0TWouWlVht+NUlcgrUURL+7vJ2yjQYQKonWUYC0UoCtXpVq",
  render_errors: [view: Gateway.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: Gateway.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
