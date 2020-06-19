# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# --------------------------------------
# Logger
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module, :request_id]

# --------------------------------------
# Phoenix
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ranch_transport_options = [
  # default: 100
  num_acceptors: 100,
  # default: 16_384
  max_connections: :infinity
]

cowboy_options = [
  idle_timeout: :infinity,
  inactivity_timeout: :infinity,
  # Experimental feature that allows using WebSocket over HTTP/2:
  enable_connect_protocol: true,
  # Headers configuration
  max_header_value_length: 16_384
]

cowboy_dispatch = [
  {:_,
   [
     {"/_rig/v1/connection/sse", RigInboundGatewayWeb.V1.SSE, :ok},
     {"/_rig/v1/connection/ws", RigInboundGatewayWeb.V1.Websocket, :ok},
     {:_, Plug.Cowboy.Handler, {RigInboundGatewayWeb.Endpoint, []}}
   ]}
]

config :rig, RigInboundGatewayWeb.Endpoint,
  server: true,
  url: [
    host: {:system, "HOST", "localhost"}
  ],
  http: [
    port: {:system, :integer, "INBOUND_PORT", 4000},
    dispatch: cowboy_dispatch,
    protocol_options: cowboy_options,
    transport_options: ranch_transport_options
  ],
  https: [
    port: {:system, :integer, "INBOUND_HTTPS_PORT", 4001},
    otp_app: :rig,
    cipher_suite: :strong,
    certfile: {:system, "HTTPS_CERTFILE", ""},
    keyfile: {:system, "HTTPS_KEYFILE", ""},
    password: {:system, "HTTPS_KEYFILE_PASS", ""},
    dispatch: cowboy_dispatch,
    protocol_options: cowboy_options,
    transport_options: ranch_transport_options
  ],
  render_errors: [view: RigInboundGatewayWeb.ErrorView, accepts: ~w(html json xml)],
  pubsub: [name: Rig.PubSub],
  check_origin: false

config :mime, :types, %{
  "text/event-stream" => ["event-stream"]
}

# --------------------------------------
# API Gateway (Proxy)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RigInboundGateway.Proxy, config_path_or_json: {:system, "PROXY_CONFIG_FILE", nil}

config :rig, RigInboundGateway.ApiProxy.Validations,
  kinesis_request_stream: {:system, "PROXY_KINESIS_REQUEST_STREAM", nil},
  kafka_request_topic: {:system, "PROXY_KAFKA_REQUEST_TOPIC", ""},
  kafka_request_avro: {:system, "PROXY_KAFKA_REQUEST_AVRO", ""},
  system: System

config :rig, RigInboundGateway.ApiProxy.Base,
  recv_timeout: {:system, :integer, "PROXY_RECV_TIMEOUT", 5_000}

config :rig, RigInboundGateway.ApiProxy.Router,
  # E.g., to enable both console and kafka loggers, use ["console", "kafka"], which
  # corresponds to REQUEST_LOG=console,kafka. Note that for the Kafka logger to actually
  # produce messages.
  active_loggers: {:system, :list, "REQUEST_LOG", []},
  logger_modules: %{
    "console" => RigInboundGateway.RequestLogger.Console,
    "kafka" => RigInboundGateway.RequestLogger.Kafka
  }

config :rig, RigInboundGateway.ApiProxy.Handler.Http,
  cors: {:system, "CORS", "*"},
  kafka_response_timeout: {:system, :integer, "PROXY_KAFKA_RESPONSE_TIMEOUT", 5_000},
  kinesis_response_timeout: {:system, :integer, "PROXY_KINESIS_RESPONSE_TIMEOUT", 5_000},
  http_async_response_timeout: {:system, :integer, "PROXY_HTTP_ASYNC_RESPONSE_TIMEOUT", 5_000}

config :rig, RigInboundGateway.ApiProxy.Handler.Kafka,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  serializer: {:system, "KAFKA_SERIALIZER", nil},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil},
  # The list of topics to consume messages from:
  consumer_topics: {:system, :list, "PROXY_KAFKA_RESPONSE_TOPICS", ["rig-proxy-response"]},
  # If KAFKA_SSL_ENABLED=0, the KAFKA_SSL_* settings are ignored; otherwise, they're required.
  ssl_enabled?: {:system, :boolean, "KAFKA_SSL_ENABLED", false},
  # If use_enabled?, the following paths are expected (relative to the `priv` directory):
  ssl_ca_certfile: {:system, "KAFKA_SSL_CA_CERTFILE", "ca.crt.pem"},
  ssl_certfile: {:system, "KAFKA_SSL_CERTFILE", "client.crt.pem"},
  ssl_keyfile: {:system, "KAFKA_SSL_KEYFILE", "client.key.pem"},
  # In case the private key is password protected:
  ssl_keyfile_pass: {:system, "KAFKA_SSL_KEYFILE_PASS", ""},
  # Credentials for SASL/Plain authentication. Example: "plain:myusername:mypassword"
  sasl: {:system, "KAFKA_SASL", nil},
  request_topic: {:system, "PROXY_KAFKA_REQUEST_TOPIC", ""},
  request_schema: {:system, "PROXY_KAFKA_REQUEST_AVRO", ""},
  cors: {:system, "CORS", "*"},
  response_timeout: {:system, :integer, "PROXY_KAFKA_RESPONSE_TIMEOUT", 5_000},
  group_id: {:system, "PROXY_KAFKA_RESPONSE_KAFKA_GROUP_ID", "rig-proxy-response"}

config :rig, RigInboundGateway.ApiProxy.Handler.Kinesis,
  kinesis_request_stream: {:system, "PROXY_KINESIS_REQUEST_STREAM", nil},
  kinesis_request_region: {:system, "PROXY_KINESIS_REQUEST_REGION", "eu-west-1"},
  response_timeout: {:system, :integer, "PROXY_KINESIS_RESPONSE_TIMEOUT", 5_000},
  cors: {:system, "CORS", "*"},
  kinesis_endpoint: {:system, "KINESIS_ENDPOINT", ""}

config :rig, RigInboundGateway.ApiProxy.Handler.Nats,
  timeout: {:system, :integer, "PROXY_NATS_RESPONSE_TIMEOUT", 60_000},
  cors: {:system, "CORS", "*"}

config :rig, RigInboundGateway.RequestLogger.Kafka,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  serializer: {:system, "KAFKA_SERIALIZER", nil},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil},
  # The list of topics to consume messages from:
  consumer_topics: [],
  # If KAFKA_SSL_ENABLED=0, the KAFKA_SSL_* settings are ignored; otherwise, they're required.
  ssl_enabled?: {:system, :boolean, "KAFKA_SSL_ENABLED", false},
  # If use_enabled?, the following paths are expected (relative to the `priv` directory):
  ssl_ca_certfile: {:system, "KAFKA_SSL_CA_CERTFILE", "ca.crt.pem"},
  ssl_certfile: {:system, "KAFKA_SSL_CERTFILE", "client.crt.pem"},
  ssl_keyfile: {:system, "KAFKA_SSL_KEYFILE", "client.key.pem"},
  # In case the private key is password protected:
  ssl_keyfile_pass: {:system, "KAFKA_SSL_KEYFILE_PASS", ""},
  # Credentials for SASL/Plain authentication. Example: "plain:myusername:mypassword"
  sasl: {:system, "KAFKA_SASL", nil},
  log_topic: {:system, "KAFKA_LOG_TOPIC", "rig-request-log"},
  log_schema: {:system, "KAFKA_LOG_SCHEMA", ""}

config :rig, RigInboundGateway.RequestLogger.ConfigValidation,
  active_loggers: {:system, :list, "REQUEST_LOG", []},
  brokers: {:system, :list, "KAFKA_BROKERS", []}

# --------------------------------------
# Transports, Channels, etc
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

cors = {:system, "CORS", "*"}

config :rig, RigInboundGatewayWeb.V1.EventController, cors: cors
config :rig, RigInboundGatewayWeb.V1.SubscriptionController, cors: cors
config :rig, RigInboundGatewayWeb.V1.SSE, cors: cors
config :rig, RigInboundGatewayWeb.V1.LongpollingController, cors: cors

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
