use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rig, RigInboundGatewayWeb.Endpoint,
  env: :test,
  http: [port: System.get_env("PORT") || 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :rig, RigInboundGateway.RateLimit,
  enabled?: true,
  avg_rate_per_sec: 0,
  burst_size: 10,
  sweep_interval_ms: 0

config :rig, RigInboundGateway.Kafka,
  log_topic: "rig"

config :rig, RigInboundGateway.Kafka.MessageHandler,
  message_user_field: "username"

config :rig, RigInboundGateway.Kafka.SupWrapper,
  message_user_field: "username",
  enabled?: false

jwt_secret_key = "mysecret"

config :rig, RigInboundGateway.Kafka.CallLogTest,
  jwt_secret_key: jwt_secret_key
config :rig, RigInboundGateway.Kafka.CallLogDisabledTest,
  jwt_secret_key: jwt_secret_key

config :rig, RigInboundGateway.Utils.Jwt,
  secret_key: jwt_secret_key

config :rig, RigInboundGatewayWeb.Presence.Channel,
  jwt_user_field: "username",
  jwt_roles_field: "role",
  privileged_roles: ["support"]

config :rig, RigInboundGatewayWeb.Presence.Controller,
  session_role: "customer"

config :rig, RigInboundGatewayWeb.ConnCase,
  jwt_secret_key: jwt_secret_key

config :rig, RigInboundGateway.Proxy,
  config_file: "proxy/proxy.test.json"

config :rig, RigInboundGatewayWeb.Proxy.Controller,
  rig_proxy: RigInboundGateway.ProxyMock
