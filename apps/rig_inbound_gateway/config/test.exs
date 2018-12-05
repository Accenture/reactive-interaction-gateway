use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rig, RigInboundGatewayWeb.Endpoint,
  env: :test,
  http: [port: System.get_env("INBOUND_PORT") || 4002],
  server: false

config :rig, RigInboundGateway.RateLimit,
  enabled?: true,
  avg_rate_per_sec: 0,
  burst_size: 10,
  sweep_interval_ms: 0

config :rig, RigInboundGateway.Kafka, log_topic: "rig"

config :rig, RigInboundGateway.Kafka.MessageHandler, message_user_field: "username"

config :rig, RigInboundGateway.Kafka.SupWrapper,
  message_user_field: "username",
  enabled?: false

config :rig, RigInboundGatewayWeb.Presence.Channel,
  jwt_user_field: "username",
  jwt_roles_field: "role",
  privileged_roles: ["support"]

config :rig, RigInboundGateway.Proxy,
  config_file: {:system, "PROXY_CONFIG_FILE", "proxy/proxy.test.json"}

config :rig, RigInboundGatewayWeb.Proxy.Controller, rig_proxy: RigInboundGateway.ProxyMock

config :fake_server, :port_range, Enum.to_list(55_000..65_000) ++ [7070]
