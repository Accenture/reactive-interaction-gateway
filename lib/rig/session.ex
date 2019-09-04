defmodule RIG.Session do
  @moduledoc """
  A session is defined by a user's JWT jti claim.

  Sessions can be blacklisted, which makes them illegal to use for a specified amount
  of time. Established connections related to a blacklisted session are terminated
  automatically.
  """
  use Rig.Config, [:jwt_session_field]

  alias JSONPointer

  alias RIG.DistributedSet

  alias __MODULE__.Connection

  require Logger

  @type session_name_t :: String.t()
  @type validity_period_t :: pos_integer()

  @blacklist_server SessionBlacklist

  # ---

  @doc "Disallow sessions with the given name for a specific amount of time."
  @spec blacklist(session_name_t, validity_period_t) :: nil
  def blacklist(session_name, validity_period_s) do
    DistributedSet.add(@blacklist_server, session_name, validity_period_s)
    Connection.terminate_all_associated_to(session_name)
  end

  # ---

  @doc "Check whether a session name has been disallowed."
  @spec blacklisted?(session_name_t) :: boolean
  def blacklisted?(session_name) do
    DistributedSet.has?(@blacklist_server, session_name)
  end

  # ---

  @doc """
  Infers the session name from JWT claims.

  - `claims`: The JWT claims map. The claim used to identify a session in an
  authorization token is defined by the `:jwt_session_field` in the module
  configuration.
  """
  @spec from_claims(claims :: map()) :: Result.t(session_name_t, String.t())
  def from_claims(claims) do
    %{jwt_session_field: jwt_session_field} = config()
    JSONPointer.get(claims, jwt_session_field)
  end

  # ---

  @doc """
  Associates a connection process to a session identifier.

  - `session_name`: If the session with the given name doesn't exist yet, it will be
  created.
  - `pid`: The client connection process. Once the associated session is terminated,
  this process will receive a `{:session_killed, <session name>}` message.
  """
  @spec register_connection(session_name_t, pid()) :: :ok
  def register_connection(session_name, connection_pid) do
    Connection.associate_session(connection_pid, session_name)

    Logger.debug(fn ->
      "Connection #{inspect(connection_pid)} is now associated to session #{inspect(session_name)}"
    end)

    :ok
  end
end
