defmodule Rig.EventHub do
  require Logger

  alias Rig.CloudEvent

  @group_prefix "rig::event::"

  @doc "Subscribes pid to a certain type of CloudEvent, optionally also to its sub-types."
  @spec subscribe(pid :: pid(), event_type :: String.t(), recursive? :: boolean) :: :ok
  def subscribe(pid, event_type, recursive?) do
    groups = subscriber_groups(event_type, recursive?)

    for group <- groups do
      :ok = :pg2.create(group)

      # PG2 does not prevent subscribing multiple times, so we do it here:
      member? = :pg2.get_members(group) |> Enum.member?(pid)

      if not member? do
        :ok = :pg2.join(group, pid)
      end
    end

    subscription_created_notification =
      CloudEvent.new("rig.subscription.create", "rig")
      |> CloudEvent.with_data(
        "application/json",
        Poison.encode!(%{
          "eventType" => event_type,
          "recursive" => recursive?
        })
      )

    send_event(pid, nil, subscription_created_notification)
  end

  @doc "Sends a CloudEvent to subscribers."
  @spec publish(cloud_event :: CloudEvent.t()) :: :ok
  def publish(cloud_event) do
    %{event_type: event_type} = cloud_event
    groups = publisher_groups(event_type)

    for group <- groups do
      :ok = :pg2.create(group)

      for client <- :pg2.get_members(group) do
        send_event(client, group, cloud_event)
        Logger.trace(fn -> "sent #{event_type} to #{group}/#{inspect(client)}" end)
      end
    end

    :ok
  end

  @spec send_event(pid(), group :: nil | String.t(), event :: CloudEvent.t()) :: :ok
  defp send_event(pid, group, event) do
    send(pid, {:rig_event, group, event})
    :ok
  end

  @doc """
  List of groups to subscribe to when interested in a given event type.

  Group names correspond to event types but are prefixed. Event types are expected to
  use a dot as a separation character. A "dot" at the end of a group name is treated
  as a (recursive) subscription to sub-events.
  """
  @spec subscriber_groups(event_type :: String.t(), recursive? :: boolean) :: [String.t(), ...]
  def subscriber_groups(event_type, recursive?),
    do: do_subscriber_groups(event_type, recursive?) |> Enum.map(&(@group_prefix <> &1))

  defp do_subscriber_groups("", false), do: []
  defp do_subscriber_groups("", true), do: ["."]
  defp do_subscriber_groups(event_type, false), do: [event_type]
  defp do_subscriber_groups(event_type, true), do: [event_type, event_type <> "."]

  @doc """
  List of groups for publishing a given event type.

  Recursive subscriptions are enabled by publishing an event to special "wildcard"
  topics. Such topics are denoted by appending a "dot" character at the end of the
  group name (see subscriber_groups/2).

  For example, the event type `com.github.pull.create` needs to go to processes in the
  following groups (group prefix omitted):

  - `com.github.pull.create`
  - `com.github.pull.`
  - `com.github.`
  - `com.`
  - `.`

  """
  @spec publisher_groups(event_type :: String.t()) :: [String.t(), ...]
  def publisher_groups(event_type) do
    legs = String.split(event_type, ".")
    do_publisher_groups(legs, length(legs)) |> Enum.map(&(@group_prefix <> &1))
  end

  defp do_publisher_groups(type_legs, n_legs, append_dot? \\ false)
  defp do_publisher_groups(_type_legs, 0, _), do: ["."]

  defp do_publisher_groups(type_legs, n_legs, append_dot?) do
    joined_legs = type_legs |> Enum.take(n_legs) |> Enum.join(".")

    # For all parent/super event types, we need a dot at the end of the group name:
    group = if append_dot?, do: joined_legs <> ".", else: joined_legs

    [group | do_publisher_groups(type_legs, n_legs - 1, true)]
  end
end
