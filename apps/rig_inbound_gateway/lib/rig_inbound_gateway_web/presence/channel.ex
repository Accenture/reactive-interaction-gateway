defmodule RigInboundGatewayWeb.Presence.Channel do
  @moduledoc """
  The presence channel is used to track a user's connected devices.

  To this end, there is also only a single room for every user. This is used,
  for instance, by the Kafka consumer code to broadcast incoming messages to the
  target users' channels, in order to distribute the messages to all connected
  devices.

  Note that keeping track of connected devices is done by the Phoenix PubSub
  module, so it also works with distributed nodes.
  """
  use RigInboundGatewayWeb, :channel
  use Rig.Config, :custom_validation
  require Logger
  alias RigInboundGatewayWeb.Presence

  # Confex callback
  defp validate_config!(config) do
    %{
      jwt_user_field: config |> Keyword.fetch!(:jwt_user_field),
      jwt_roles_field: config |> Keyword.fetch!(:jwt_roles_field),
      privileged_roles: MapSet.new(config |> Keyword.fetch!(:privileged_roles))
    }
  end

  @doc """
  The room name for a specific user.
  """
  @spec user_channel_name(String.t) :: String.t
  def user_channel_name(username), do: "user:#{username}"

  @doc """
  The room name for a specific role.
  """
  @spec role_channel_name(String.t) :: String.t
  def role_channel_name(role), do: "role:#{role}"

  defp extract_username_and_roles(socket) do
    user_info = socket.assigns.user_info
    conf = config()

    {
      _username = Map.fetch!(user_info, conf.jwt_user_field),
      _roles    = Map.fetch!(user_info, conf.jwt_roles_field)
    }
  end

  @doc """
  Join a channel.

  For `user:*` channels, joining is only allowed for the owner of the channel (e.g.,
  alice for `user:alice`) or for a person that has elevated privileges (= has
  authorized role). The same applies to `role:*` channels, except that they have no
  owner, so only users with an authorized role are permitted.

  """
  @spec join(String.t, map, map) :: {atom, map}
  def join("user:" <> user_subtopic_name = room, _params, socket) do
    {username, roles} = extract_username_and_roles(socket)
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

  @spec join(String.t, map, map) :: {atom, map}
  def join("role:" <> _ = room, _params, socket) do
    {username, roles} = extract_username_and_roles(socket)
    if has_authorized_role?(roles) do
      authorized_join(room, username, socket)
    else
      unauthorized_join(room, username)
    end
  end

  @doc """
  Sends off outgoing messages.

  Apparently, this is needed as soon as an external PubSub server is in use, as this
  disables "fastlane" - the result is that a different callback is being used that
  expects this method to be implemented (see `Phoenix.Channel.Server`). According to
  the docs, without fastlane the performance is degraded, but it doesn't state to what
  extent.
  """
  def handle_out(event, payload, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  @doc """
  Start tracking presences.

  """
  @spec handle_info({:after_join, String.t, [String.t]}, map) :: {:noreply, map}
  def handle_info({:after_join, username, roles}, socket) do
    # track global role channels
    push(socket, "presence_state", Presence.list(socket))
    track_multiple_presences("role", roles, socket)

    # track user specific channel
    track_presence("user:#{username}", socket)

    {:noreply, socket}
  end

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
    user_field = config().jwt_user_field
    username = socket.assigns.user_info |> Map.fetch!(user_field)

    {:ok, _} = Presence.track(
      socket.channel_pid,
      topic,
      username,
      Map.merge(socket.assigns.user_info,
        %{
          time: System.system_time(:millisecond),
          address: "192.168.0.1",
          device: "desktop",
          browser: "Chrome",
        }
      )
    )
  end

  @spec has_authorized_role?(list(String.t)) :: boolean
  defp has_authorized_role?(roles) do
    roles
    |> MapSet.new
    |> MapSet.intersection(config().privileged_roles)
    |> MapSet.size
    |> Kernel.>(0)
  end

  @spec authorized_join(String.t, String.t, map) :: {:ok, map}
  defp authorized_join(room, username, socket) do
    Logger.debug(fn -> "user #{inspect username} has joined #{room}" end)
    {:ok, socket}
  end

  @spec unauthorized_join(String.t, String.t) :: {:error, String.t}
  defp unauthorized_join(room, username) do
    msg = "unauthorized user with id #{inspect username} tried to join #{inspect room}!"
    Logger.warn(msg)
    {:error, msg}
  end
end
