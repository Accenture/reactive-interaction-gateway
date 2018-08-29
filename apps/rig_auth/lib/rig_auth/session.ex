defmodule RigAuth.Session do
  @moduledoc """
  Session tracking from authorization-header tokens.
  """
  use Rig.Config, [:jwt_session_field]

  alias Rig.SessionHub
  alias RigAuth.Jwt.Utils, as: Jwt
  alias Rig.DistributedSet

  @type session_name_t :: String.t()
  @type validity_period_t :: pos_integer()

  @blacklist_server SessionBlacklist

  @doc "Disallow sessions with the given name for a specific amount of time."
  @spec blacklist(session_name_t, validity_period_t) :: nil
  def blacklist(session_name, validity_period_s) do
    DistributedSet.add(@blacklist_server, session_name, validity_period_s)
    SessionHub.kill(session_name)
  end

  @doc "Check whether a session name has been disallowed."
  @spec blacklisted?(session_name_t) :: boolean
  def blacklisted?(session_name) do
    DistributedSet.has?(@blacklist_server, session_name)
  end

  @spec update(Plug.Conn.t(), pid()) :: nil
  def update(conn, pid) do
    %{jwt_session_field: jwt_session_field} = config()
    do_update(conn, pid, jwt_session_field)
  end

  defp do_update(_, _, nil), do: nil
  defp do_update(_, _, ""), do: nil

  defp do_update(conn, pid, jwt_session_field) do
    tokens = Map.get(conn.assigns, :auth_tokens, [])

    session_names =
      for {"bearer", token} <- tokens do
        case Jwt.decode(token) do
          {:ok, token_map} -> Map.get(token_map, jwt_session_field)
          _ -> ""
        end
      end
      |> Enum.reject(fn x -> x == "" end)

    for session <- session_names do
      SessionHub.join(pid, session)
    end
  end
end
