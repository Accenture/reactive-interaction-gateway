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

  @authorized_roles ["support"]

  @doc """
  The room name for a specific user.
  """
  def room_name(username), do: "user:#{username}"

  @doc """
  Join user specific channel. Only owner of given channel or user with authorized
  role is able to join.
  """
  @spec join(String.t, map, map) :: {atom, map}
  def join(room = "user:" <> user_subtopic_name, _params, socket) do
    %{"username" => username, "role" => roles} = socket.assigns.user_info

    cond do
      username == user_subtopic_name ->
        send(self(), {:after_join, username, roles})
        authorized_join(room, username, socket)
      has_authorized_role?(roles) ->
        send(self(), {:after_join, user_subtopic_name})
        authorized_join(room, username, socket)
      true -> unauthorized_join(room, username)
    end
  end

  @doc """
  Join common role based channel. Only user with authorized role is able to join.
  """
  @spec join(String.t, map, map) :: {atom, map}
  def join(room = "role:" <> _, _params, socket) do
    %{"username" => username, "role" => roles} = socket.assigns.user_info
    if has_authorized_role?(roles) do
      authorized_join(room, username, socket)
    else
      unauthorized_join(room, username)
    end
  end

  @doc """
  Start tracking of user in global role baes channels and also in his specific channel.
  """
  @spec handle_info({:after_join, list(String.t), String.t}, map) :: {:noreply, map}
  def handle_info({:after_join, username, roles}, socket) do
    # track global role channels
    push(socket, "presence_state", Presence.list(socket))
    track_multiple_presences("role", roles, socket)

    # track user specific channel
    track_presence("user:#{username}", socket)

    {:noreply, socket}
  end

  @doc """
  Start tracking of user in his specific channel.
  """
  @spec handle_info({:after_join, String.t}, map) :: {:noreply, map}
  def handle_info({:after_join, username}, socket) do
    # track user specific channel
    track_presence("user:#{username}", socket)
    {:noreply, socket}
  end

  @doc """
  List all presences in given topic.
  """
  @spec channels_list(String.t) :: map
  def channels_list(topic), do: Presence.list(topic)

  @spec track_multiple_presences(String.t, list(String.t), map) :: any
  defp track_multiple_presences(topic_namespace, subtopics, socket) do
    Enum.each(subtopics, fn(subtopic) ->
      track_presence("#{topic_namespace}:#{subtopic}", socket)
    end)
  end

  @spec track_presence(String.t, map) :: any
  defp track_presence(topic, socket) do
    %{"username" => username} = socket.assigns.user_info

    {:ok, _} = Presence.track(
      socket.channel_pid,
      topic,
      username,
      Map.merge(socket.assigns.user_info,
        %{
          time: System.system_time(:milli_seconds),
          address: "192.168.0.1",
          device: "desktop",
          browser: "Chrome",
        }
      )
    )
  end

  @spec has_authorized_role?(list(String.t)) :: boolean
  defp has_authorized_role?(roles) do
    valid_roles_length =
      roles
      |> Enum.into(MapSet.new)
      |> MapSet.intersection(Enum.into(@authorized_roles, MapSet.new))
      |> MapSet.size
    valid_roles_length > 0
  end

  @spec authorized_join(String.t, String.t, map) :: {:ok, map}
  defp authorized_join(room, username, socket) do
    Logger.debug("user #{inspect username} has joined #{room}")
    {:ok, socket}
  end

  @spec unauthorized_join(String.t, String.t) :: {:error, String.t}
  defp unauthorized_join(room, username) do
    Logger.warn(msg = "unauthorized user with id #{inspect username} tried to join #{inspect room}!")
    {:error, msg}
  end
end
