use Mix.Config

config :rig, RigKafka.Client, serializer: {:system, "KAFKA_SERIALIZER", nil}

config :rig, RigKafka.Avro,
  schema_registry_host: {:system, "KAFKA_SCHEMA_REGISTRY_HOST", "localhost:8081"}
