use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rig, RigInboundGatewayWeb.Endpoint,
  env: :test,
  http: [port: System.get_env("INBOUND_PORT") || 4001],
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

config :rig, RigInboundGateway.ImplicitSubscriptions.Jwt,
  extractor_config_path_or_json:
    {:system, "EXTRACTORS",
     "{\"event_one\":{\"name\":{\"stable_field_index\":1,\"jwt\":{\"json_pointer\":\"\/username\"},\"event\":{\"json_pointer\":\"\/data\/name\"}}},\"event_two\":{\"fullname\":{\"stable_field_index\":1,\"jwt\":{\"json_pointer\":\"\/fullname\"},\"event\":{\"json_pointer\":\"\/data\/fullname\"}},\"name\":{\"stable_field_index\":1,\"jwt\":{\"json_pointer\":\"\/username\"},\"event\":{\"json_pointer\":\"\/data\/name\"}}},\"example\":{\"email\":{\"stable_field_index\":1,\"event\":{\"json_pointer\":\"\/data\/email\"}}}}"}
