# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# --------------------------------------
# Logger
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module, :request_id]

# --------------------------------------
# Phoenix
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig_inbound_gateway, RigInboundGatewayWeb.Endpoint,
  url: [
    host: {:system, "HOST", "localhost"}
  ],
  http: [
    port: {:system, :integer, "PORT", 4000}
  ],
  render_errors: [view: RigInboundGatewayWeb.ErrorView, accepts: ~w(html json xml)],
  pubsub: [name: Rig.PubSub]

# --------------------------------------
# API Gateway (Proxy)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RigInboundGateway.Proxy,
  config_file: {:system, "PROXY_CONFIG_FILE", nil}
config :rig, RigInboundGatewayWeb.Proxy.Controller,
  rig_proxy: RigInboundGateway.Proxy

config :rig, RigInboundGateway.RateLimit,
  # Internal ETS table name (must be unique).
  table_name: :rate_limit_buckets,
  # Enables/disables rate limiting globally.
  enabled?: {:system, :boolean, "RATE_LIMIT_ENABLED", false},
  # If true, the remote IP is taken into account; otherwise the limits are per endpoint only.
  per_ip?: {:system, :boolean, "RATE_LIMIT_PER_IP", true},
  # The permitted average amount of requests per second.
  avg_rate_per_sec: {:system, :integer, "RATE_LIMIT_AVG_RATE_PER_SEC", 10_000},
  # The permitted peak amount of requests.
  burst_size: {:system, :integer, "RATE_LIMIT_BURST_SIZE", 5_000},
  # GC interval. If set to zero, GC is disabled.
  sweep_interval_ms: {:system, :integer, "RATE_LIMIT_SWEEP_INTERVAL_MS", 5_000}

# --------------------------------------
# User Roles
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# A connection is only considered a "session" if the user is member of the `session_role` as
# defined here and stated in the JWT. For example, if you need a system user that should not show
# up when listing active users, just make sure the user does not assume the session role.
session_role = {:system, "SESSION_ROLE", "user"}

# Users that belong to a privileged role are allowed to subscribe to messages of any user. Role
# names are case-sensitive. By default, there are no privileged roles.
# For example, to allow all users in the "admin" and "support" groups to subscribe to any
# messages, you could use start RIG with `PRIVILEGED_ROLES=admin,support`.
privileged_roles = {:system, :list, "PRIVILEGED_ROLES", []}

# --------------------------------------
# Authorization Token (JWT)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# JWT payload fields:
jwt_payload_field_map = %{
  # The claim holding the user ID:
  user: {:system, "JWT_USER_FIELD", "user"},
  # The claim holding the user's roles:
  roles: {:system, "JWT_ROLES_FIELD", "roles"}
}

# --------------------------------------
# Transports, Channels, etc
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RigInboundGateway.Transports.ServerSentEvents,
  user_channel_name_mf: {RigInboundGatewayWeb.Presence.Channel, :user_channel_name},
  role_channel_name_mf: {RigInboundGatewayWeb.Presence.Channel, :role_channel_name}

config :rig, RigInboundGatewayWeb.Presence.Channel,
  # See "JWT payload fields"
  jwt_user_field: jwt_payload_field_map.user,
  # See "JWT payload fields"
  jwt_roles_field: jwt_payload_field_map.roles,
  # See "User Roles"
  privileged_roles: privileged_roles

config :rig, RigInboundGatewayWeb.Presence.Controller,
  # See "User Roles"
  session_role: session_role

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
