use Mix.Config

config :rig, Rig.Kafka, enabled?: true

config :rig, Rig.KafkaTest, topic: "rig"

# Print only warnings and errors during test
config :rig, Rig.Application,
  log_level: {:system, "LOG_LEVEL", "warn"},
  prometheus_metrics_enabled?: {:system, :boolean, "PROMETHEUS_METRICS_ENABLED", false}

jwt_secret_key = "mysecret"
jwt_alg = "HS256"

config :rig, RigApi.ConnCase, jwt_secret_key: jwt_secret_key

config :rig, RigApi.ConnCase, jwt_secret_key: jwt_secret_key

config :rig, RigInboundGateway.Kafka.CallLogTest, jwt_secret_key: jwt_secret_key

config :rig, RigInboundGateway.Kafka.CallLogDisabledTest, jwt_secret_key: jwt_secret_key
