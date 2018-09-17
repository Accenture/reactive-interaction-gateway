defmodule RigInboundGateway.Events do
  @moduledoc """
  Utility functions used in more than one controller.
  """
  alias Rig.CloudEvent
  alias Rig.Connection
  alias Rig.Subscription

  @spec welcome_event() :: CloudEvent.t()
  def welcome_event do
    connection_pid = self()
    connection_token = Connection.Codec.serialize(connection_pid)
    data = %{connection_token: connection_token}

    CloudEvent.new!(%{
      "eventType" => "rig.connection.create",
      "source" => "rig"
    })
    |> CloudEvent.with_data(data)
  end

  @spec subscription_create(Subscription.t()) :: CloudEvent.t()
  def subscription_create(%Subscription{} = subscription) do
    CloudEvent.new!(%{
      "eventType" => "rig.subscription.create",
      "source" => "rig"
    })
    |> CloudEvent.with_data(%{
      "eventType" => subscription.event_type,
      "constraints" => subscription.constraints
    })
  end
end
