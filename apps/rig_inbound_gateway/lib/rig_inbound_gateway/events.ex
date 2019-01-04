defmodule RigInboundGateway.Events do
  @moduledoc """
  Utility functions used in more than one controller.
  """
  alias UUID

  alias Rig.Connection
  alias Rig.Subscription
  alias RigCloudEvents.CloudEvent

  @spec welcome_event() :: CloudEvent.t()
  def welcome_event do
    connection_pid = self()
    connection_token = Connection.Codec.serialize(connection_pid)

    CloudEvent.parse!(%{
      specversion: "0.2",
      type: "rig.connection.create",
      source: "rig",
      id: UUID.uuid4(),
      data: %{connection_token: connection_token}
    })
  end

  @spec subscriptions_set([Subscription.t()]) :: CloudEvent.t()
  def subscriptions_set(subscriptions) do
    CloudEvent.parse!(%{
      specversion: "0.2",
      type: "rig.subscriptions_set",
      source: "rig",
      id: UUID.uuid4(),
      data:
        Enum.map(subscriptions, fn %Subscription{event_type: event_type, constraints: constraints} ->
          %{"eventType" => event_type, "oneOf" => constraints}
        end)
    })
  end
end
