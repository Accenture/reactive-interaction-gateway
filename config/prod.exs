use Mix.Config

# Do not print debug messages in production
config :logger, level: :warn

# --------------------------------------
# Peerage
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, Rig.Discovery,
  discovery_type: {:system, "DISCOVERY_TYPE", nil},
  dns_name: {:system, "DNS_NAME", "localhost"}
