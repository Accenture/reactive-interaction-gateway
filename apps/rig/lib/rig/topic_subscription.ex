defmodule Rig.TopicSubscription do
  @moduledoc "Subscribe a user's connection to a topic."

  alias RigAuth.Jwt.Utils, as: Jwt
  alias Phoenix.PubSub
  alias Phoenix.Channel.Server, as: PhoenixChannelServer

  @pubsub_server Rig.PubSub

  @type topic_t :: String.t
  @type user_id_t :: String.t
  @type jwt_t :: String.t

  @type transport_pid_t :: pid
  @spec subscribe_transport_to_topic(transport_pid_t, topic_t, jwt_t) ::
          :ok | {:error, term()}
  def subscribe_transport_to_topic(transport_pid, topic, jwt) do
    if public_topic?(topic) do
      do_subscribe(transport_pid, topic, nil)
    else
      with {:ok, %{"user" => user_id}} <- Jwt.decode(jwt),
           true <- eligible_to_subscribe?(user_id, topic) || {:error, :denied} do
        do_subscribe(transport_pid, topic, user_id)
      else
        {:error, _} = err -> err
      end
    end
  end

  defp public_topic?("public:" <> _subtopic), do: true
  defp public_topic?(_), do: false

  @spec eligible_to_subscribe?(user_id_t, topic_t) :: boolean
  # Users are allowed to subscribe to their own user topic.
  defp eligible_to_subscribe?(user_id, "user:" <> subtopic) when subtopic == user_id, do: true
  # Users are allowed to subscribe to public topics; all other topics are denied.
  defp eligible_to_subscribe?(_user_id, topic), do: public_topic?(topic)

  @spec do_subscribe(pid(), topic_t, user_id? :: user_id_t | nil) ::
          :ok | {:error, term()}
  defp do_subscribe(pid, topic, user_id?) do
    PubSub.subscribe(Rig.PubSub, pid, topic, link: true)
    broadcast_presence("joined", topic, %{pid: pid, user_id: user_id?})
  end

  defp broadcast_presence(event, topic, payload) do
    PhoenixChannelServer.broadcast(@pubsub_server, presence_topic(topic), event, payload)
  end

  defp presence_topic(topic) do
    case String.split(topic, ":") do
      [category | _] when byte_size(category) > 0 -> "presence:" <> category
      _ -> "presence:" <> topic
    end
  end

  @spec unsubscribe_transport_from_topic(transport_pid_t, topic_t) :: none()
  def unsubscribe_transport_from_topic(transport_pid, topic) do
    PubSub.unsubscribe(Rig.PubSub, transport_pid, topic)
    broadcast_presence("left", topic, %{pid: transport_pid})
  end
end
