use Mix.Config

config :rig_api, RigApi.Endpoint,
  # debug_errors: true, # Uncomment to see full error descriptions in API as HTML
  env: :dev,
  check_origin: false,
  watchers: []

config :phoenix, :stacktrace_depth, 20
