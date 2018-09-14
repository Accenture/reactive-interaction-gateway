defmodule Rig.Connection.Api do
  @moduledoc """
  Talk to a connection process.
  """
  alias Rig.Subscription

  @doc """
  Create a new subscription.

  Typically called by the subscription controller to register a new subscription with
  a socket process. The socket process will subsequently start passing on the
  subscription to the respective filter processes periodically.

  """
  @spec register_subscription(pid, Subscription.t()) :: :ok
  def register_subscription(socket_pid, %Subscription{} = subscription) do
    send(socket_pid, {:register_subscription, subscription})
    :ok
  end
end
