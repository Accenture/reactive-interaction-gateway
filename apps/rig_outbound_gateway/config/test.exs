use Mix.Config

config :rig, RigOutboundGateway.Kafka.MessageHandler,
  message_user_field: "username",
  user_channel_name_mf: nil

config :rig, RigOutboundGateway.Kafka.SupWrapper,
  message_user_field: "username",
  enabled?: false
