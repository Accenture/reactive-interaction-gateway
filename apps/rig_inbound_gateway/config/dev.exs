use Mix.Config

config :rig_inbound_gateway, RigInboundGatewayWeb.Endpoint,
  # debug_errors: true, # Uncomment to see full error descriptions in API as HTML
  env: :dev,
  check_origin: false,
  watchers: [],
  https: [
    certfile: "cert/selfsigned.pem",
    keyfile: "cert/selfsigned_key.des3.pem",
    password: "test"
  ]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
