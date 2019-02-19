use Mix.Config

config :rig_inbound_gateway, RigInboundGatewayWeb.Endpoint,
  env: :prod,
  watchers: [],
  https: [
    certfile: {:system, "HTTPS_CERTFILE", ""},
    keyfile: {:system, "HTTPS_KEYFILE", ""}
  ]

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :rig, RigInboundGateway.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
# import_config "prod.secret.exs"
