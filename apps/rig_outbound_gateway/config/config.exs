use Mix.Config

# --------------------------------------
# Kafka
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# Kafka JSON message fields:
kafka_message_field_map = %{
  # Name of the JSON property holding the user ID of the recipient:
  user: {:system, "KAFKA_USER_FIELD", "user"}
}

brod_client_id = :rig_brod_client

config :rig, RigOutboundGateway,
  message_user_field: kafka_message_field_map.user

config :rig, RigOutboundGateway.Kafka.GroupSubscriber,
  brod_client_id: brod_client_id,
  consumer_group: {:system, "KAFKA_CONSUMER_GROUP", "rig-consumer-group"},
  source_topics: {:system, :list, "KAFKA_SOURCE_TOPICS", ["rig"]}

config :rig, RigOutboundGateway.Kafka.MessageHandler,
  message_user_field: kafka_message_field_map.user,
  user_channel_name_mf: {RigWeb.Presence.Channel, :user_channel_name}

config :rig, RigOutboundGateway.Kafka.SupWrapper,
  enabled?: {:system, :boolean, "KAFKA_ENABLED", false}

config :rig, RigOutboundGateway.Kafka.Sup,
  brod_client_id: brod_client_id,
  hosts: {:system, :list, "KAFKA_HOSTS", ["localhost:9092"]}
config :rig, RigOutboundGateway.Kafka.SupOld,
  brod_client_id: brod_client_id,
  hosts: {:system, :list, "KAFKA_HOSTS", ["localhost:9092"]}

import_config "#{Mix.env()}.exs"
