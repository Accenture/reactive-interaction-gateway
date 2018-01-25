use Mix.Config

config :rig_api, RigApi.Endpoint,
  env: :test,
  http: [port: System.get_env("PORT") || 4011],
  server: false

config :rig, RigApi.ApisController,
  rig_proxy: RigInboundGateway.ProxyMock
