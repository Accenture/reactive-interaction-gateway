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

  def join(room = "presence:" <> user_subtopic_name, _params, socket) do
    username = Map.fetch!(socket.assigns.user_info, "username")
    if user_subtopic_name != username do
      Logger.warn(msg = "user with id #{inspect username} tried to join #{inspect room} (only own room allowed)!")
      {:error, msg}
    else
      Logger.debug("user #{inspect username} has joined #{room}")
      {:ok, socket}
    end
  end
end
