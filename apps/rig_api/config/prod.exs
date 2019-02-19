use Mix.Config

config :rig_api, RigApi.Endpoint,
  env: :prod,
  check_origin: false,
  https: [
    certfile: {:system, "HTTPS_CERTFILE", ""},
    keyfile: {:system, "HTTPS_KEYFILE", ""}
  ]

config :phoenix, :serve_endpoints, true
