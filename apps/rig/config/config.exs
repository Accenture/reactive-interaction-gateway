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

config :rig, Rig.EventFilter.Sup, extractor_config_path_or_json: extractor_path_or_json

config :rig, RIG.JWT, jwt_conf: jwt_conf

config :rig, RIG.Subscriptions,
  jwt_conf: jwt_conf,
  extractor_path_or_json: extractor_path_or_json

config :rig, Rig.EventStream.KafkaToFilter,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
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
  group_id: {:system, "KAFKA_GROUP_ID", "rig"}

config :rig, Rig.EventStream.KafkaToHttp,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  # The list of topics to consume messages from:
  consumer_topics: {:system, :list, "FIREHOSE_KAFKA_SOURCE_TOPICS", ["rig-firehose"]},
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
  group_id: {:system, "KAFKA_GROUP_ID", "rig"}

config :porcelain, driver: Porcelain.Driver.Basic

import_config "#{Mix.env()}.exs"
