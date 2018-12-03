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
    port: {:system, :integer, "INBOUND_PORT", 4000},
    dispatch: [
      {:_,
       [
         {"/_rig/v1/connection/ws", RigInboundGatewayWeb.V1.Websocket, []},
         {:_, Plug.Adapters.Cowboy.Handler, {RigInboundGatewayWeb.Endpoint, []}}
       ]}
    ]
  ],
  render_errors: [view: RigInboundGatewayWeb.ErrorView, accepts: ~w(html json xml)],
  pubsub: [name: Rig.PubSub],
  check_origin: false

config :mime, :types, %{
  "text/event-stream" => ["event-stream"]
}

# --------------------------------------
# API Gateway (Proxy)
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

config :rig, RigInboundGateway.Proxy, config_file: {:system, "PROXY_CONFIG_FILE", nil}

config :rig, RigInboundGateway.ApiProxy.Base,
  recv_timeout: {:system, :integer, "PROXY_RECV_TIMEOUT", 5_000}

config :rig, RigInboundGateway.ApiProxy.Router,
  # E.g., to enable both console and kafka loggers, use ["console", "kafka"], which
  # corresponds to REQUEST_LOG=console,kafka. Note that for the Kafka logger to actually
  # produce messages, KAFKA_ENABLED=1 has to be set as well.
  active_loggers: {:system, :list, "REQUEST_LOG", []},
  logger_modules: %{
    "console" => RigInboundGateway.RequestLogger.Console,
    "kafka" => RigInboundGateway.RequestLogger.Kafka
  }

config :rig, RigInboundGateway.ApiProxy.Handler.Http,
  cors: {:system, "CORS", "*"},
  kafka_response_timeout: {:system, :integer, "PROXY_KAFKA_RESPONSE_TIMEOUT", 5_000},
  kinesis_response_timeout: {:system, :integer, "PROXY_KINESIS_RESPONSE_TIMEOUT", 5_000}

config :rig, RigInboundGateway.ApiProxy.Handler.Kafka,
  # The list of brokers, given by a comma-separated list of host:port items:
  brokers: {:system, :list, "KAFKA_BROKERS", []},
  # The list of topics to consume messages from:
  consumer_topics: {:system, :list, "PROXY_KAFKA_RESPONSE_TOPICS", ["rig-proxy-response"]},
  # If KAFKA_SSL_ENABLED=0, the KAFKA_SSL_* settings are ignored; otherwise, they're required.
  ssl_enabled?: {:system, :boolean, "KAFKA_SSL_ENABLED", false},
  # If use_enabled?, the following paths are expected (relative to the `priv` directory):
  ssl_ca_certfile: {:system, "KAFKA_SSL_CA_CERTFILE", "ca.crt.pem"},
  ssl_certfile: {:system, "KAFKA_SSL_CERTFILE", "client.crt.pem"},
  ssl_keyfile: {:system, "KAFKA_SSL_KEYFILE", "client.key.pem"},
  # In case the private key is password protected:
  ssl_keyfile_pass: {:system, "KAFKA_SSL_KEYFILE_PASS", ""},
  # Credentials for SASL/Plain authentication. Example: "plain:myusername:mypassword"
  sasl: {:system, "KAFKA_SASL", nil},
  request_topic: {:system, "PROXY_KAFKA_REQUEST_TOPIC", ""},
  cors: {:system, "CORS", "*"},
  response_timeout: {:system, :integer, "PROXY_KAFKA_RESPONSE_TIMEOUT", 5_000}

config :rig, RigInboundGateway.ApiProxy.Handler.Kinesis,
  kinesis_request_stream: {:system, "PROXY_KINESIS_REQUEST_STREAM", nil},
  kinesis_request_region: {:system, "PROXY_KINESIS_REQUEST_REGION", "eu-west-1"},
  response_timeout: {:system, :integer, "PROXY_KINESIS_RESPONSE_TIMEOUT", 5_000},
  cors: {:system, "CORS", "*"}

config :rig, RigInboundGateway.RequestLogger.Kafka,
  log_topic: {:system, "KAFKA_LOG_TOPIC", "rig-request-log"}

config :rig, RigInboundGatewayWeb.Proxy.Controller, rig_proxy: RigInboundGateway.Proxy

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

config :rig, RigAuth.Session, jwt_session_field: {:system, "JWT_SESSION_FIELD", nil}

config :rig, RigAuth.AuthorizationCheck.Subscription,
  validation_type: {:system, "SUBSCRIPTION_CHECK", "NO_CHECK"}

config :rig, RigAuth.AuthorizationCheck.Submission,
  validation_type: {:system, "SUBMISSION_CHECK", "NO_CHECK"}

config :rig, RigInboundGateway.ImplicitSubscriptions.Jwt,
  extractor_config_path_or_json: {:system, "EXTRACTORS", nil}

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

cors = {:system, "CORS", "*"}

config :rig, RigInboundGatewayWeb.V1.EventController, cors: cors
config :rig, RigInboundGatewayWeb.V1.SubscriptionController, cors: cors
config :rig, RigInboundGatewayWeb.V1.SSE, cors: cors

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
