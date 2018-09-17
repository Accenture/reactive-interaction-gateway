defmodule Rig.EventFilter do
  alias Rig.CloudEvent
  alias Rig.EventFilter.Server, as: Filter
  alias Rig.EventFilter.Sup, as: FilterSup
  alias Rig.Subscription

  @doc """
  Refresh an existing subscription.

  Typically called periodically by socket processes for each of their subscriptions.
  Registers the subscription with all Filter Supervisors on all nodes, using a PG2
  process group to find them.

  """
  @spec refresh_subscriptions([Subscription.t()]) :: :ok
  def refresh_subscriptions(subscriptions) do
    # There is one Filter Supervisor per node. Each of those supervisors forwards the
    # subscriptions to the right Filter processes on the node they're located on.
    for pid <- FilterSup.processes() do
      GenServer.call(pid, {:refresh_subscriptions, subscriptions})
    end

    :ok
  end

  @spec forward_event(CloudEvent.t()) :: :ok
  def forward_event(%{"eventType" => event_type} = event) do
    # On any node, there is only one Filter process for a given event type, or none, if
    # there are no subscriptions for the event type.
    with name <- Filter.process(event_type) do
      GenServer.cast(name, {:cloud_event, event})
    end

    :ok
  end
end
