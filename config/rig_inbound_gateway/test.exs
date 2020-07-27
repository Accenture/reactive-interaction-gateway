use Mix.Config

config :rig, RigInboundGatewayWeb.Endpoint,
  env: :test,
  https: [
    certfile: "cert/selfsigned.pem",
    keyfile: "cert/selfsigned_key.des3.pem",
    password: "test"
  ]

config :rig, RigInboundGateway.Kafka, log_topic: "rig"

config :rig, RigInboundGateway.Proxy,
  config_path_or_json: {:system, "PROXY_CONFIG_FILE", "proxy/proxy.test.inbound.json"}

config :rig, RigInboundGateway.ApiProxy.Validations,
  kinesis_request_stream: {:system, "PROXY_KINESIS_REQUEST_STREAM", "test-request-stream"},
  kafka_request_topic: {:system, "PROXY_KAFKA_REQUEST_TOPIC", "test-request-topic"},
  kafka_request_avro: {:system, "PROXY_KAFKA_REQUEST_AVRO", ""},
  system: RigInboundGateway.SystemMock

config :fake_server, :port_range, Enum.to_list(55_000..65_000) ++ [7070, 8081]
