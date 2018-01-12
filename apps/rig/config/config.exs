use Mix.Config

config :rig, Rig.Kafka,
  # must match rig_outbound_gateway's config:
  brod_client_id: :rig_brod_client,
  enabled?: {:system, :boolean, "KAFKA_ENABLED", false},
  produce_fn: &:brod.produce_sync/5
