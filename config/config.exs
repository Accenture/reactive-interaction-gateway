# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :gateway, Gateway.Endpoint,
  url: [host: System.get_env("HOST") || "localhost"],
  http: [port: System.get_env("PORT") || 4000],
  jwt_key: "supersecrettoken",
  secret_key_base: "qjiJFnMIbw3Bs2lbM0TWouWlVht+NUlcgrUURL+7vJ2yjQYQKonWUYC0UoCtXpVq",
  render_errors: [view: Gateway.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: Gateway.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module, :request_id]

# Kafka
kafka_default_client = :gateway_brod_client

config :gateway, :kafka, %{
  kafka_default_client: kafka_default_client,
  consumer_group_id: "gateway-consumer-group",
  topics: ["message"],
}

# Read by brod_sup (which is started as an application by mix)
# and used to start the default brod client.
config :brod,
  clients: [
    {kafka_default_client, [
      endpoints: ["0.0.0.0": 9092]
    ]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Proxy route config file location
config :gateway, proxy_route_config: "priv/proxy/proxy.json"