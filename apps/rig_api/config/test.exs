use Mix.Config

config :rig_api, RigApi.Endpoint,
  env: :test,
  https: [
    certfile: "cert/selfsigned.pem",
    keyfile: "cert/selfsigned_key.des3.pem",
    password: "test"
  ]

config :rig, RigApi.ApisController, rig_proxy: RigInboundGateway.ProxyMock

config :rig, :event_filter, Rig.EventFilterMock
