use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gateway, GatewayWeb.Endpoint,
  env: :test,
  http: [port: System.get_env("PORT") || 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :gateway, Gateway.RateLimit,
  enabled?: true,
  avg_rate_per_sec: 0,
  burst_size: 10,
  sweep_interval_ms: 0

config :gateway, Gateway.Kafka.MessageHandler,
  message_user_field: "username"

config :gateway, Gateway.Kafka.SupWrapper,
  message_user_field: "username",
  enabled?: false

jwt_secret_key = "supersecrettoken"

config :gateway, Gateway.Kafka.CallLogTest,
  jwt_secret_key: jwt_secret_key

config :gateway, Gateway.Utils.Jwt,
  secret_key: jwt_secret_key

config :gateway, GatewayWeb.Presence.Channel,
  jwt_user_field: "username",
  jwt_roles_field: "role",
  privileged_roles: ["support"]

config :gateway, GatewayWeb.Presence.Controller,
  session_role: "customer"

config :gateway, GatewayWeb.ConnCase,
  jwt_secret_key: jwt_secret_key

config :gateway, Gateway.Proxy,
  config_file: "proxy/proxy.test.json"