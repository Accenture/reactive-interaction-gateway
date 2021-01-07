use Mix.Config

# Do not print debug messages in production
config :rig, Rig.Application, log_level: {:system, "LOG_LEVEL", "warn"}

# --------------------------------------
# Peerage
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RIG.Discovery,
  discovery_type: {:system, "DISCOVERY_TYPE", nil},
  dns_name: {:system, "DNS_NAME", "localhost"}
