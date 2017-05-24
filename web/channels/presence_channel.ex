defmodule Gateway.PresenceChannel do
  @moduledoc """
  The presence channel is used to track a user's connected devices.

  To this end, there is also only a single room for every user. This is used,
  for instance, by the Kafka consumer code to broadcast incoming messages to the
  target users' channels, in order to distribute the messages to all connected
  devices.

  Note that keeping track of connected devices is done by the Phoenix PubSub
  module, so it also works with distributed nodes.
  """
  use Gateway.Web, :channel
  require Logger
  alias Gateway.Presence

  @authorised_roles ["support"]

  @doc """
  The room name for a specific user.
  """
  def room_name(username), do: "presence:#{username}"

  @doc """
  Join user specific channel. Only owner of given channel or user with authorised
  role is able to join.
  """
  @spec join(String.t, map, map) :: {atom, map}
  def join(room = "presence:" <> user_subtopic_name, _params, socket) do
    %{"username" => username, "role" => roles} = socket.assigns.user_info

    cond do
      username == user_subtopic_name ->
        send(self(), {:after_join, roles})
        join_channel(:ok, room, username, socket)
      has_authorised_role?(roles) -> join_channel(:ok, room, username, socket)
      true -> join_channel(:error, room, username)
    end
  end

  @doc """
  Join common role based channel. Only user with authorised role is able to join.
  """
  @spec join(String.t, map, map) :: {atom, map}
  def join(room = "presence.role:" <> _, _params, socket) do
    %{"username" => username, "role" => roles} = socket.assigns.user_info
    if has_authorised_role?(roles) do
      join_channel(:ok, room, username, socket)
    else
      join_channel(:error, room, username)
    end
  end

  @doc """
  Send broadcast announce to role based channels after user joined his own channel.
  """
  @spec handle_info({:after_join, list(String.t), String.t}, map) :: {:noreply, map}
  def handle_info({:after_join, roles}, socket) do
    push(socket, "presence_state", Presence.list(socket))
    track_presence(socket, roles)
    {:noreply, socket}
  end

  defp track_presence(socket, roles) do
    %{"username" => username} = socket.assigns.user_info
    Enum.each(roles, fn(role) ->
      {:ok, _} = Presence.track(socket.channel_pid, "presence.role:" <> role, username, %{
        online_at: inspect(System.system_time(:seconds))
      })
    end)
  end

  @spec has_authorised_role?(list(String.t)) :: boolean
  defp has_authorised_role?(roles) do
    length(roles -- (roles -- @authorised_roles)) > 0
  end

  @spec join_channel(:ok, String.t, String.t, map) :: {:ok, map}
  defp join_channel(:ok, room, username, socket) do
    Logger.debug("user #{inspect username} has joined #{room}")
    {:ok, socket}
  end

  @spec join_channel(:error, String.t, String.t) :: {:error, String.t}
  defp join_channel(:error, room, username) do
    Logger.warn(msg = "unauthorised user with id #{inspect username} tried to join #{inspect room}!")
    {:error, msg}
  end
end
