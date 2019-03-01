use Mix.Config

config :rig_api, RigApi.Endpoint,
  # debug_errors: true, # Uncomment to see full error descriptions in API as HTML
  env: :dev,
  check_origin: false,
  watchers: [],
  https: [
    certfile: "cert/selfsigned.pem",
    keyfile: "cert/selfsigned_key.des3.pem",
    password: "test"
  ]

config :phoenix, :stacktrace_depth, 20
