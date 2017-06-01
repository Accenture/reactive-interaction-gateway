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
  def join(room = "user:" <> user_subtopic_name, params, socket) do
    %{"username" => username, "role" => roles} = socket.assigns.user_info
    IO.inspect Map.keys(socket.transport)
    IO.inspect params
    cond do
      username == user_subtopic_name ->
        send(self(), {:after_join, roles})
        authorized_join(room, username, socket)
      has_authorized_role?(roles) -> authorized_join(room, username, socket)
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
  Send broadcast announce to role based channels after user joined his own channel.
  """
  @spec handle_info({:after_join, list(String.t), String.t}, map) :: {:noreply, map}
  def handle_info({:after_join, roles}, socket) do
    push(socket, "presence_state", Presence.list(socket))
    track_presence(socket, roles)
    {:noreply, socket}
  end
  
  def channels_list() do
    Presence.list("role:customer")
  end

  defp track_presence(socket, roles) do
    %{"username" => username} = socket.assigns.user_info
    Enum.each(roles, fn(role) ->
      {:ok, _} = Presence.track(socket.channel_pid, "role:" <> role, username, %{
        online_at: inspect(System.system_time(:seconds)),
        jwt_payload: socket.assigns.user_info,
      })
    end)
  end

  @spec has_authorized_role?(list(String.t)) :: boolean
  defp has_authorized_role?(roles) do
    valid_roles_length =
      MapSet.intersection(Enum.into(roles, MapSet.new), Enum.into(@authorized_roles, MapSet.new))
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
