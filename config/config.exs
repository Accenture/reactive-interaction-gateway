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

config :rig, Rig.EventStream.KafkaToHttp,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  serializer: {:system, "KAFKA_SERIALIZER", nil},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil},
  # The list of topics to consume messages from:
  consumer_topics: {:system, :list, "FIREHOSE_KAFKA_SOURCE_TOPICS", ["rig"]},
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
  # HTTP endpoints to invoke for each Kafka message:
  targets: {:system, :list, "FIREHOSE_KAFKA_HTTP_TARGETS", []},
  group_id: {:system, "KAFKATOHTTP_KAFKA_GROUP_ID", "rig-kafka-to-http"}

config :rig, Rig.Connection.Codec,
  codec_secret_key: {:system, "NODE_COOKIE", nil},
  codec_default_key: "7tsf4Y6GTOfPY1iDo4PqZA=="

config :rig, RigInboundGatewayWeb.VConnection,
  idle_connection_timeout: {:system, "IDLE_CONNECTION_TIMEOUT", "300000"}

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

config :rig, Rig.Application, log_level: {:system, :atom, "LOG_LEVEL", :debug}

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

config :rig, Rig.Discovery,
  discovery_type: {:system, "DISCOVERY_TYPE", nil},
  dns_name: {:system, "DNS_NAME", "localhost"}

config :rig, RigInboundGateway.Metadata,
  jwt_fields: %{"userid" => "sub"},
  indexed_metadata: ["userid"]
  # TODO: If needed, check jwt values against metadata values; error and return 404 if they don't match; lo prio; current state: if fields don't match, jwt is prio and metadata value for a specific key gets overwritten
  # has_compare: false
  # compare_strict: %{"jwt/userid" => "meta/userid"}

import_config "#{Mix.env()}.exs"

import_config "rig_api/config.exs"
import_config "rig_inbound_gateway/config.exs"
import_config "rig_metrics/config.exs"
import_config "rig_outbound_gateway/config.exs"
import_config "rig_tests/config.exs"
