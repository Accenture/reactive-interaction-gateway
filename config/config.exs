use Mix.Config

# By default, the umbrella project as well as each child
# application will require this configuration file, ensuring
# they all use the same configuration. While one could
# configure all applications here, we prefer to delegate
# back to each application for organization purposes.
import_config "../apps/*/config/config.exs"

# --------------------------------------
# Logger
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

metadata = [
  # phoenix_metadata
  :request_id,
  # kafka_metadata
  :raw,
  :topic,
  :partition,
  :offset,
  #
  :application,
  :module,
  :function,
  :file,
  :line,
  :pid,
  :registered_name,
  :crash_reason
]

config :logger, :console,
  format: "\n$time [$level] $levelpad$message\n$metadata\n",
  metadata: metadata |> Enum.uniq()

config :rig, Rig.Application, log_level: {:system, :atom, "LOG_LEVEL", :debug}

# --------------------------------------
# Authorization Token (JWT)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

jwt_secret_key = {:system, "JWT_SECRET_KEY", ""}
jwt_alg = {:system, "JWT_ALG", "HS256"}

config :rig, RigAuth,
  secret_key: jwt_secret_key,
  alg: jwt_alg

config :rig, RigAuth.Jwt.Utils,
  secret_key: jwt_secret_key,
  alg: jwt_alg

# --------------------------------------
# Peerage
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, Rig.Discovery,
  discovery_type: {:system, "DISCOVERY_TYPE", nil},
  dns_name: {:system, "DNS_NAME", "localhost"}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
