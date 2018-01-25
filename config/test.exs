use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

jwt_secret_key = "mysecret"

config :rig, RigAuth.Jwt.Utils,
  secret_key: jwt_secret_key

config :rig, RigAuth.ConnCase,
  jwt_secret_key: jwt_secret_key

config :rig, RigApi.ConnCase,
  jwt_secret_key: jwt_secret_key

config :rig, RigInboundGatewayWeb.ConnCase,
  jwt_secret_key: jwt_secret_key

config :rig, RigInboundGateway.Kafka.CallLogTest,
  jwt_secret_key: jwt_secret_key

config :rig, RigInboundGateway.Kafka.CallLogDisabledTest,
  jwt_secret_key: jwt_secret_key

session_role = "customer"

config :rig, RigApi.ChannelsController,
  session_role: session_role

config :rig, RigInboundGatewayWeb.Presence.Controller,
  session_role: session_role
