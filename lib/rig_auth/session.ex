defmodule RigAuth.Session do
  @moduledoc """
  Session tracking from authorization-header tokens.
  """
  use Rig.Config, [:jwt_session_field]

  alias JSONPointer

  alias Rig.DistributedSet
  alias RIG.JWT
  alias Rig.SessionHub

  require Logger

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

    results =
      for {"bearer", token} <- tokens do
        token
        |> JWT.parse_token()
        |> Result.and_then(fn claims -> JSONPointer.get(claims, jwt_session_field) end)
        |> Result.and_then(fn session_name -> Result.ok(SessionHub.join(pid, session_name)) end)
      end

    Logger.debug(fn ->
      msg = results |> Result.filter_and_unwrap_err() |> Enum.map(&inspect/1) |> Enum.join(", ")
      "Session update errors: #{msg}"
    end)
  end
end
