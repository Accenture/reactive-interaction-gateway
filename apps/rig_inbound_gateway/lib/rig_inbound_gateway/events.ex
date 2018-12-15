defmodule RigInboundGateway.Events do
  @moduledoc """
  Utility functions used in more than one controller.
  """
  alias CloudEvent
  alias Rig.Connection
  alias Rig.Subscription

  @spec welcome_event() :: CloudEvent.t()
  def welcome_event do
    connection_pid = self()
    connection_token = Connection.Codec.serialize(connection_pid)
    data = %{connection_token: connection_token}

    CloudEvent.new!(%{
      "cloudEventsVersion" => "0.1",
      "eventType" => "rig.connection.create",
      "source" => "rig"
    })
    |> CloudEvent.with_data(data)
  end

  @spec subscriptions_set([Subscription.t()]) :: CloudEvent.t()
  def subscriptions_set(subscriptions) do
    CloudEvent.new!(%{
      "cloudEventsVersion" => "0.1",
      "eventType" => "rig.subscriptions_set",
      "source" => "rig"
    })
    |> CloudEvent.with_data(
      subscriptions
      |> Enum.map(fn %Subscription{event_type: event_type, constraints: constraints} ->
        %{"eventType" => event_type, "oneOf" => constraints}
      end)
    )
  end
end
