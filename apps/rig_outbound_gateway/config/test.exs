use Mix.Config

restart_delay_ms = {:system, :integer, "KAFKA_RESTART_DELAY_MS", 100}

config :rig, RigOutboundGateway.Kafka.SupWrapper,
  restart_delay_ms: restart_delay_ms

config :rig, RigOutboundGateway.Kafka.Sup,
  restart_delay_ms: restart_delay_ms
