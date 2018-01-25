use Mix.Config

config :rig_api, RigApi.Endpoint,
  env: :prod,
  check_origin: false

config :phoenix, :serve_endpoints, true
