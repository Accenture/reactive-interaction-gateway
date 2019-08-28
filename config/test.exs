use Mix.Config

config :rig, Rig.Kafka, enabled?: true

config :rig, Rig.KafkaTest, topic: "rig"

# Print only warnings and errors during test
config :rig, Rig.Application, log_level: {:system, :atom, "LOG_LEVEL", :warn}

jwt_secret_key = "mysecret"
jwt_alg = "HS256"

config :rig, RigAuth.Jwt.Utils, secret_key: {:system, "JWT_SECRET_KEY", jwt_secret_key}

config :rig, RigAuth.ConnCase,
  jwt_secret_key: {:system, "JWT_SECRET_KEY", jwt_secret_key},
  jwt_alg: {:system, "JWT_ALG", jwt_alg}

config :rig, RigApi.ConnCase, jwt_secret_key: jwt_secret_key

config :rig, RigApi.ConnCase, jwt_secret_key: jwt_secret_key

config :rig, RigInboundGateway.Kafka.CallLogTest, jwt_secret_key: jwt_secret_key

config :rig, RigInboundGateway.Kafka.CallLogDisabledTest, jwt_secret_key: jwt_secret_key
