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

  @broadcast &Gateway.Endpoint.broadcast/3
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
        send(self(), {:after_join, roles, "-joined"})
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
  Leaving common role based channel sends broadcast message to common role based channels.
  """
  @spec terminate(String.t, map) :: {:noreply, map}
  def terminate(_reason, socket) do
    %{"role" => roles} = socket.assigns.user_info
    broadcast_announce(roles, "-left", %{})
    {:noreply, socket}
  end

  @doc """
  Send broadcast announce to role based channels after user joined his own channel.
  """
  @spec handle_info({:after_join, list(String.t), String.t}, map) :: {:noreply, map}
  def handle_info({:after_join, roles, event}, socket) do
    broadcast_announce(roles, event, %{})
    {:noreply, socket}
  end

  @spec broadcast_announce(list(String.t), String.t, map) :: any
  defp broadcast_announce(roles, event, data) do
    Enum.each(roles, fn(role) ->
      Logger.debug("broadcasting in topic presence.role:#{role} to event #{role}#{event}")
      @broadcast.("presence.role:" <> role, role <> event, data)
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
