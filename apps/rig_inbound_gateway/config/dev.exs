use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :rig, RigInboundGatewayWeb.Endpoint,
  # debug_errors: true, # Uncomment to see full error descriptions in API as HTML
  env: :dev,
  check_origin: false,
  watchers: []

# Do not include metadata nor timestamps in development logs TODO why?
#config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
