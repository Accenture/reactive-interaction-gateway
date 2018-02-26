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

config :rig, RigOutboundGateway.Kafka.GroupSubscriber,
  brod_client_id: brod_client_id,
  consumer_group: {:system, "KAFKA_CONSUMER_GROUP", "rig-consumer-group"},
  source_topics: {:system, :list, "KAFKA_SOURCE_TOPICS", ["rig"]}

config :rig, RigOutboundGateway.Kafka.SupWrapper,
  enabled?: {:system, :boolean, "KAFKA_ENABLED", false}

config :rig, RigOutboundGateway.Kafka.Sup,
  brod_client_id: brod_client_id,
  hosts: {:system, :list, "KAFKA_HOSTS", ["localhost:9092"]}

config :rig, RigOutboundGateway.Kinesis.JavaClient,
  enabled?: {:system, :boolean, "KINESIS_ENABLED", false},
  client_jar: {:system, "KINESIS_CLIENT_JAR", "./kinesis-client/target/rig-kinesis-client-1.0-SNAPSHOT.jar"},
  # will default to the one from the Erlang installation:
  otp_jar: {:system, "KINESIS_OTP_JAR", nil},
  log_level: {:system, "KINESIS_LOGLEVEL", "INFO"},
  kinesis_app_name: {:system, "KINESIS_APP_NAME", "Reactive-Interaction-Gateway"},
  kinesis_aws_region: {:system, "KINESIS_AWS_REGION", "eu-west-1"},
  kinesis_stream: {:system, "KINESIS_STREAM", "RIG-outbound"}

config :porcelain, driver: Porcelain.Driver.Basic

import_config "#{Mix.env()}.exs"
