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


import_config "#{Mix.env()}.exs"
