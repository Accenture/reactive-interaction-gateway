use Mix.Config

config :rig_inbound_gateway, RigInboundGatewayWeb.Endpoint,
  env: :test,
  https: [
    certfile: "cert/selfsigned.pem",
    keyfile: "cert/selfsigned_key.des3.pem",
    password: "test"
  ]

config :rig, RigInboundGateway.Kafka, log_topic: "rig"

config :rig, RigInboundGateway.Proxy,
  config_path_or_json: {:system, "PROXY_CONFIG_FILE", "proxy/proxy.test.json"}

config :fake_server, :port_range, Enum.to_list(55_000..65_000) ++ [7070]
