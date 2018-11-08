defmodule RigInboundGateway.Subscriptions do
  @moduledoc """
  Create subscription structures from subscription definitions - map of events and their constraints
  """
  require Logger

  alias Rig.Subscription

  def check_and_forward_subscriptions(socket_pid, subscriptions) do
    subscriptions
    |> Enum.map(&Subscription.new/1)
    |> Enum.group_by(fn
      %Subscription{} -> :good
      _ -> :bad
    end)
    |> case do
      %{bad: bad} ->
        {:error, :could_not_parse_subscriptions, bad}

      %{good: good} ->
        send(socket_pid, {:set_subscriptions, good})
        :ok

      %{} ->
        send(socket_pid, {:set_subscriptions, []})
        :ok
    end
  end
end
