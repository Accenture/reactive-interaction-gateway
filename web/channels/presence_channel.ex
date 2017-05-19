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

  @doc """
  The room name for a specific user.
  """
  def room_name(username), do: "presence:#{username}"

  @authorized_roles ["support"]

  @spec join(String.t, map, map) :: tuple
  def join(room = "presence:" <> user_subtopic_name, _params, socket) do
    %{"username" => username, "role" => roles} = socket.assigns.user_info

    cond do
      username == user_subtopic_name -> join_channel(:ok, room, username, socket)
      length(roles -- (roles -- @authorized_roles)) > 0 -> join_channel(:ok, room, username, socket)
      true -> join_channel(:error, room, username)
    end
  end

  @spec join_channel(:ok, String.t, String.t, map) :: tuple
  defp join_channel(:ok, room, username, socket) do
    Logger.debug("user #{inspect username} has joined #{room}")
    {:ok, socket}
  end

  @spec join_channel(:error, String.t, String.t) :: tuple
  defp join_channel(:error, room, username) do
    Logger.warn(msg = "user with id #{inspect username} tried to join #{inspect room} (only own room allowed)!")
    {:error, msg}
  end
end
