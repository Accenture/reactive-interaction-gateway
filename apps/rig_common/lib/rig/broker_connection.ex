defmodule Rig.BrokerConnection do
  @moduledoc ~S"""
  Interface to any publish-subscribe capable broker service.
  """

  alias RigCloudEvents.CloudEvent

  @type connection :: any
  @type topic :: String.t()
  @type callback :: (CloudEvent.t() -> :ok | {:error, any})
  @type subscription_id :: any

  @callback subscribe(connection, topic, callback) :: {:ok, subscription_id} | {:error, any}
  @callback unsubscribe(subscription_id) :: :ok
  @callback publish(connection, topic, key :: String.t(), CloudEvent.t()) :: :ok
end
