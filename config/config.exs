use Mix.Config

extractor_path_or_json = {:system, "EXTRACTORS", nil}
# config :rig, :jwt_conf, %{
#   key: {:system, "JWT_SECRET_KEY", ""},
#   alg: {:system, "JWT_ALG", "HS256"}
# }
jwt_conf = %{
  key: {:system, "JWT_SECRET_KEY", ""},
  alg: {:system, "JWT_ALG", "HS256"}
}

config :rig, TodoFakeModuleCauseUpdateDocsCannotHandleNestedTuples,
  key: {:system, "JWT_SECRET_KEY", ""},
  alg: {:system, "JWT_ALG", "HS256"}

config :rig, Rig.EventFilter.Sup, extractor_config_path_or_json: extractor_path_or_json

config :rig, RIG.JWT, jwt_conf: jwt_conf

config :rig, RIG.Subscriptions,
  jwt_conf: jwt_conf,
  extractor_path_or_json: extractor_path_or_json

config :rig, Rig.EventStream.KafkaToFilter,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  serializer: {:system, "KAFKA_SERIALIZER", nil},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil},
  # The list of topics to consume messages from:
  consumer_topics: {:system, :list, "KAFKA_SOURCE_TOPICS", ["rig"]},
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
  group_id: {:system, "KAFKATOFILTER_KAFKA_GROUP_ID", "rig-kafka-to-filter"}

config :rig, Rig.EventStream.NatsToFilter,
  # The list of servers, given by a comma-separated list of host:port items:
  servers: {:system, :list, "NATS_SERVERS", []},
  # The list of topics to consume messages from:
  topics: {:system, :list, "NATS_SOURCE_TOPICS", ["rig"]},
  queue_group: {:system, "NATSTOFILTER_QUEUE_GROUP", "rig-nats-to-filter"}

config :rig, Rig.Connection.Codec,
  codec_secret_key: {:system, "NODE_COOKIE", nil},
  codec_default_key: "7tsf4Y6GTOfPY1iDo4PqZA=="

config :porcelain, driver: Porcelain.Driver.Basic

# --------------------------------------
# Logger
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

metadata = [
  # phoenix_metadata
  :request_id,
  # kafka_metadata
  :raw,
  :topic,
  :partition,
  :offset,
  #
  :application,
  :module,
  :function,
  :file,
  :line,
  :pid,
  :registered_name,
  :crash_reason
]

config :logger, :console,
  format: "\n$time [$level] $levelpad$message\n$metadata\n",
  metadata: metadata |> Enum.uniq()

config :rig, Rig.Application,
  log_level: {:system, :atom, "LOG_LEVEL", :debug},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil}

# --------------------------------------
# Session and Authorization
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RIG.Session, jwt_session_field: {:system, "JWT_SESSION_FIELD", "/jti"}

config :rig, RIG.AuthorizationCheck.Subscription,
  validation_type: {:system, "SUBSCRIPTION_CHECK", "NO_CHECK"}

config :rig, RIG.AuthorizationCheck.Submission,
  validation_type: {:system, "SUBMISSION_CHECK", "NO_CHECK"}

# --------------------------------------
# Peerage
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RIG.Discovery,
  discovery_type: {:system, "DISCOVERY_TYPE", nil},
  dns_name: {:system, "DNS_NAME", "localhost"}

import_config "#{Mix.env()}.exs"

import_config "rig_api/config.exs"
import_config "rig_inbound_gateway/config.exs"
import_config "rig_metrics/config.exs"
import_config "rig_outbound_gateway/config.exs"
import_config "rig_tests/config.exs"

# --------------------------------------
# Jaeger
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RIG.Tracing,
  jaeger_host: {:system, :charlist, "JAEGER_HOST", ''},
  jaeger_port: {:system, :integer, "JAEGER_PORT", 6831},
  jaeger_service_name: {:system, :charlist, "JAEGER_SERVICE_NAME", 'rig'},
  zipkin_address: {:system, :charlist, "ZIPKIN_ADDR", ''},
  zipkin_service_name: {:system, "ZIPKIN_SERVICE_NAME", "rig"}

# --------------------------------------
# Connections rate limiting
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

max_connections_per_minute = {:system, :integer, "MAX_CONNECTIONS_PER_MINUTE", 5000}
max_connections_per_minute_bucket = "max-connections-per-minute"

config :rig, RigInboundGatewayWeb.ConnectionLimit,
  max_connections_per_minute: max_connections_per_minute,
  max_connections_per_minute_bucket: max_connections_per_minute_bucket

config :rig, RigInboundGateway.ConnectionTest,
  max_connections_per_minute_bucket: max_connections_per_minute_bucket

# --------------------------------------
# Phoenix
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :phoenix, :json_library, Jason
