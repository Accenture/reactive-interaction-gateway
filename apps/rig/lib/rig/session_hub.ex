defmodule Rig.SessionHub do
  @moduledoc """
  Tracking sessions and sending signals to kill off connections.
  """
  require Logger

  @group_prefix "rig::session::"

  @doc "Joins (or creates) a session."
  @spec join(pid :: pid(), session_name :: String.t()) :: :ok
  def join(pid, session_name) do
    group = @group_prefix <> session_name

    # Ensure the session (group) exists:
    :ok = :pg2.create(group)

    # PG2 does not prevent subscribing multiple times, so we do it here:
    member? = :pg2.get_members(group) |> Enum.member?(pid)

    if not member? do
      :ok = :pg2.join(group, pid)
    end
  end

  @doc "Deletes a session and notifies all subscribers."
  @spec kill(session_name :: String.t()) :: :ok
  def kill(session_name) do
    group = @group_prefix <> session_name

    case :pg2.get_members(group) do
      {:error, {:no_such_group, ^group}} ->
        :ok

      members ->
        for pid <- members, do: send(pid, {:rig_session_killed, group})
        :ok = :pg2.delete(group)
    end
  end
end
