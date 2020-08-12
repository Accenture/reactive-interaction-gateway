use Mix.Config

config :rig, RigApi.Endpoint,
  env: :test,
  https: [
    certfile: "cert/selfsigned.pem",
    keyfile: "cert/selfsigned_key.des3.pem",
    password: "test"
  ]

config :rig, RigApi.V1.APIs, rig_proxy: RigInboundGateway.ProxyMock
config :rig, RigApi.V2.APIs, rig_proxy: RigInboundGateway.ProxyMock
config :rig, RigApi.V3.APIs, rig_proxy: RigInboundGateway.ProxyMock

config :rig, :event_filter, Rig.EventFilterMock
