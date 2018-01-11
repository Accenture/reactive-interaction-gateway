use Mix.Config

config :rig, RigAuth.Blacklist,
  default_expiry_hours: {:system, :integer, "JWT_BLACKLIST_DEFAULT_EXPIRY_HOURS", 1}
