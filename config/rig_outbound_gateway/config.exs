use Mix.Config

# --------------------------------------
# Kafka
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RigOutboundGateway.Kinesis.JavaClient,
  enabled?: {:system, :boolean, "KINESIS_ENABLED", false},
  client_jar:
    {:system, "KINESIS_CLIENT_JAR", "./kinesis-client/target/rig-kinesis-client-1.0-SNAPSHOT.jar"},
  # will default to the one from the Erlang installation:
  otp_jar: {:system, "KINESIS_OTP_JAR", nil},
  log_level: {:system, "KINESIS_LOG_LEVEL", "INFO"},
  kinesis_app_name: {:system, "KINESIS_APP_NAME", "Reactive-Interaction-Gateway"},
  kinesis_aws_region: {:system, "KINESIS_AWS_REGION", "eu-west-1"},
  kinesis_stream: {:system, "KINESIS_STREAM", "RIG-outbound"},
  kinesis_endpoint: {:system, "KINESIS_ENDPOINT", ""},
  dynamodb_endpoint: {:system, "KINESIS_DYNAMODB_ENDPOINT", ""}

config :porcelain, driver: Porcelain.Driver.Basic
