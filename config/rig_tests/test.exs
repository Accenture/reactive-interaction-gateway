use Mix.Config

config :rig, :systest_kafka_config, %{
  consumer_topics: [],
  ssl_enabled?: false
}

config :rig, RigTests.Proxy.ResponseFrom.KafkaTest,
  server_id: :rig_proxy_responsefrom_kafkatest_genserver,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  serializer: {:system, "KAFKA_SERIALIZER", nil},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil},
  # The list of topics to consume messages from:
  consumer_topics: {:system, :list, "KAFKA_SOURCE_TOPICS", []},
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
  response_topic: {:system, "PROXY_KAFKA_RESPONSE_TOPICS", "rig-proxy-response"}

config :rig, RigTests.Proxy.PublishToEventStream.KafkaTest,
  server_id: :rig_proxy_publish_kafkatest_genserver,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  serializer: {:system, "KAFKA_SERIALIZER", nil},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil},
  # The list of topics to consume messages from:
  consumer_topics: {:system, :list, "KAFKA_SOURCE_TOPICS", []},
  # If KAFKA_SSL_ENABLED=0, the KAFKA_SSL_* settings are ignored; otherwise, they're required.
  ssl_enabled?: {:system, :boolean, "KAFKA_SSL_ENABLED", false},
  # If use_enabled?, the following paths are expected (relative to the `priv` directory):
  ssl_ca_certfile: {:system, "KAFKA_SSL_CA_CERTFILE", "ca.crt.pem"},
  ssl_certfile: {:system, "KAFKA_SSL_CERTFILE", "client.crt.pem"},
  ssl_keyfile: {:system, "KAFKA_SSL_KEYFILE", "client.key.pem"},
  # In case the private key is password protected:
  ssl_keyfile_pass: {:system, "KAFKA_SSL_KEYFILE_PASS", ""},
  # Credentials for SASL/Plain authentication. Example: "plain:myusername:mypassword"
  sasl: {:system, "KAFKA_SASL", nil}

config :rig, RigTests.Avro.AvroTest,
  server_id: :rig_avro_kafkatest_genserver,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  serializer: {:system, "KAFKA_SERIALIZER", nil},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil},
  # The list of topics to consume messages from:
  consumer_topics: {:system, :list, "KAFKA_SOURCE_TOPICS", []},
  # If KAFKA_SSL_ENABLED=0, the KAFKA_SSL_* settings are ignored; otherwise, they're required.
  ssl_enabled?: {:system, :boolean, "KAFKA_SSL_ENABLED", false},
  # If use_enabled?, the following paths are expected (relative to the `priv` directory):
  ssl_ca_certfile: {:system, "KAFKA_SSL_CA_CERTFILE", "ca.crt.pem"},
  ssl_certfile: {:system, "KAFKA_SSL_CERTFILE", "client.crt.pem"},
  ssl_keyfile: {:system, "KAFKA_SSL_KEYFILE", "client.key.pem"},
  # In case the private key is password protected:
  ssl_keyfile_pass: {:system, "KAFKA_SSL_KEYFILE_PASS", ""},
  # Credentials for SASL/Plain authentication. Example: "plain:myusername:mypassword"
  sasl: {:system, "KAFKA_SASL", nil}

config :rig, RigTests.Proxy.RequestLogger.KafkaTest,
  server_id: :rig_proxy_logger_kafkatest_genserver,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  serializer: {:system, "KAFKA_SERIALIZER", nil},
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", nil},
  # The list of topics to consume messages from:
  consumer_topics: ["rig-request-log"],
  # If KAFKA_SSL_ENABLED=0, the KAFKA_SSL_* settings are ignored; otherwise, they're required.
  ssl_enabled?: {:system, :boolean, "KAFKA_SSL_ENABLED", false},
  # If use_enabled?, the following paths are expected (relative to the `priv` directory):
  ssl_ca_certfile: {:system, "KAFKA_SSL_CA_CERTFILE", "ca.crt.pem"},
  ssl_certfile: {:system, "KAFKA_SSL_CERTFILE", "client.crt.pem"},
  ssl_keyfile: {:system, "KAFKA_SSL_KEYFILE", "client.key.pem"},
  # In case the private key is password protected:
  ssl_keyfile_pass: {:system, "KAFKA_SSL_KEYFILE_PASS", ""},
  # Credentials for SASL/Plain authentication. Example: "plain:myusername:mypassword"
  sasl: {:system, "KAFKA_SASL", nil}

config :rig, RigTests.Proxy.ResponseFrom.KinesisTest, response_topic: "rig-proxy-response"
