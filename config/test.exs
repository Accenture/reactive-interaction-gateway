use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :rig, RigWeb.Endpoint,
  env: :test,
  http: [port: System.get_env("PORT") || 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :rig, Rig.RateLimit,
  enabled?: true,
  avg_rate_per_sec: 0,
  burst_size: 10,
  sweep_interval_ms: 0

config :rig, Rig.Kafka.MessageHandler,
  message_user_field: "username"

config :rig, Rig.Kafka.SupWrapper,
  message_user_field: "username",
  enabled?: false

jwt_secret_key = "mysecret"

config :rig, Rig.Kafka.CallLogTest,
  jwt_secret_key: jwt_secret_key

config :rig, Rig.Utils.Jwt,
  secret_key: jwt_secret_key

config :rig, RigWeb.Presence.Channel,
  jwt_user_field: "username",
  jwt_roles_field: "role",
  privileged_roles: ["support"]

config :rig, RigWeb.Presence.Controller,
  session_role: "customer"

config :rig, RigWeb.ConnCase,
  jwt_secret_key: jwt_secret_key

config :rig, Rig.Proxy,
  config_file: "proxy/proxy.test.json"

config :rig, RigWeb.Proxy.Controller,
  rig_proxy: Rig.ProxyMock
