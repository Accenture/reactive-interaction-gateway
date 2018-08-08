use Mix.Config

config :rig, Rig.Kafka,
  enabled?: true

config :rig, Rig.KafkaTest,
  topic: "rig"
