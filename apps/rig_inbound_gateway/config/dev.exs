use Mix.Config

config :rig_inbound_gateway, RigInboundGatewayWeb.Endpoint,
  # debug_errors: true, # Uncomment to see full error descriptions in API as HTML
  env: :dev,
  check_origin: false,
  watchers: []

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
