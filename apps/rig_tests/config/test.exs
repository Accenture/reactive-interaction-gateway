use Mix.Config

config :rig, :systest_kafka_config, %{
  brokers: [{"localhost", 9092}],
  consumer_topics: [],
  ssl_enabled?: false
}

config :rig, RigTests.Proxy.ResponseFrom.KafkaTest, response_topic: "rig-proxy-response"

config :rig, RigTests.Proxy.ResponseFrom.KinesisTest, response_topic: "rig-proxy-response"
