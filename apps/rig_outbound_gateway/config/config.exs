use Mix.Config

# --------------------------------------
# Common
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RigOutboundGateway,
  message_user_field: {:system, "MESSAGE_USER_FIELD", "user"}

# --------------------------------------
# Kafka
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

brod_client_id = :rig_brod_client
firehose_brod_client_id = :rig_firehose_brod_client
restart_delay_ms = {:system, :integer, "KAFKA_RESTART_DELAY_MS", 20_000}

config :rig, RigOutboundGateway.Kafka.Readiness,
  brod_client_id: brod_client_id

config :rig, RigOutboundGateway.Kafka.GroupSubscriber,
  brod_client_id: brod_client_id,
  consumer_group: {:system, "KAFKA_CONSUMER_GROUP", "rig-consumer-group"},
  source_topics: {:system, :list, "KAFKA_SOURCE_TOPICS", ["rig"]},
  kafka_response_topic: {:system, "PROXY_KAFKA_RESPONSE_TOPIC", nil}

config :rig, RigOutboundGateway.Kafka.SupWrapper,
  enabled?: {:system, :boolean, "KAFKA_ENABLED", false},
  restart_delay_ms: restart_delay_ms

config :rig, RigOutboundGateway.Kafka.Sup,
  restart_delay_ms: restart_delay_ms,
  brod_client_id: brod_client_id,
  hosts: {:system, :list, "KAFKA_HOSTS", ["localhost:9092"]},
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

  config :rig, RigOutboundGateway.Firehose.Readiness,
    brod_client_id: firehose_brod_client_id

  config :rig, RigOutboundGateway.Firehose.GroupSubscriber,
    brod_client_id: firehose_brod_client_id,
    consumer_group: {:system, "FIREHOSE_KAFKA_CONSUMER_GROUP", "rig-firehose-consumer-group"},
    source_topics: {:system, :list, "FIREHOSE_KAFKA_SOURCE_TOPICS", ["rig-firehose"]},
    targets: {:system, :list, "FIREHOSE_KAFKA_HTTP_TARGETS", ["http://localhost:4040/todo"]}

  config :rig, RigOutboundGateway.Firehose.SupWrapper,
    enabled?: {:system, :boolean, "KAFKA_ENABLED", false},
    restart_delay_ms: restart_delay_ms

  config :rig, RigOutboundGateway.Firehose.Sup,
    restart_delay_ms: restart_delay_ms,
    brod_client_id: firehose_brod_client_id,
    hosts: {:system, :list, "KAFKA_HOSTS", ["localhost:9092"]},
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

config :rig, RigOutboundGateway.Kinesis.JavaClient,
  enabled?: {:system, :boolean, "KINESIS_ENABLED", false},
  client_jar: {:system, "KINESIS_CLIENT_JAR", "./kinesis-client/target/rig-kinesis-client-1.0-SNAPSHOT.jar"},
  # will default to the one from the Erlang installation:
  otp_jar: {:system, "KINESIS_OTP_JAR", nil},
  log_level: {:system, "KINESIS_LOG_LEVEL", "INFO"},
  kinesis_app_name: {:system, "KINESIS_APP_NAME", "Reactive-Interaction-Gateway"},
  kinesis_aws_region: {:system, "KINESIS_AWS_REGION", "eu-west-1"},
  kinesis_stream: {:system, "KINESIS_STREAM", "RIG-outbound"},
  kinesis_endpoint: {:system, "KINESIS_ENDPOINT", ""},
  dynamodb_endpoint: {:system, "KINESIS_DYNAMODB_ENDPOINT", ""}

config :porcelain, driver: Porcelain.Driver.Basic

import_config "#{Mix.env()}.exs"
