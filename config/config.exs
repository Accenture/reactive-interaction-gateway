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

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
