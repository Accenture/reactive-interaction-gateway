defmodule Rig.EventStream.NatsToFilter do
  @moduledoc """
  Subscribes to a [NATS] topic and forwards messages to the event filter by event type.

  [NATS]: https://nats.io
  """
  require Logger

  use Supervisor
  use Rig.Config, [:servers, :topics, :queue_group]

  alias Rig.EventFilter
  alias RigCloudEvents.CloudEvent

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    %{servers: servers} = config()

    if Enum.empty?(servers) do
      :ignore
    else
      supervise_nats_connection()
    end
  end

  defp supervise_nats_connection do
    %{servers: servers, topics: topics, queue_group: queue_group} = config()

    servers =
      servers
      |> Rig.Config.parse_socket_list()
      |> Enum.map(fn {host, port} -> %{host: String.to_charlist(host), port: port} end)

    Logger.info(fn ->
      "Setting up NATS subscriptions to #{inspect(topics)} via #{inspect(servers)}"
    end)

    # The ConnectionSupervisor restores connections in case of failure.

    connection_name = :nats
    connection_sup_opts = %{name: connection_name, connection_settings: servers}
    connection_sup_name = String.to_atom("#{__MODULE__}.nats_connection_sup")

    # The ConsumerSupervisor restores subscriptions after a connection loss.

    subscriber_sup_name = String.to_atom("#{__MODULE__}.nats_subscriber_sup")
    subscriptions = for topic <- topics, do: %{topic: topic, queue_group: queue_group}

    subscriber_sup_opts = %{
      connection_name: connection_name,
      consuming_function: {__MODULE__, :handle_message},
      subscription_topics: subscriptions
    }

    # The ConnectionSupervisor is started before the ConsumerSupervisor.
    import Supervisor.Spec

    children = [
      worker(Gnat.ConnectionSupervisor, [connection_sup_opts, [name: connection_sup_name]]),
      worker(Gnat.ConsumerSupervisor, [subscriber_sup_opts, [name: subscriber_sup_name]],
        shutdown: 30_000
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def handle_message(message) do
    case CloudEvent.parse(message.body) do
      {:ok, %CloudEvent{} = cloud_event} ->
        Logger.debug(fn -> inspect(cloud_event.parsed) end)
        EventFilter.forward_event(cloud_event)

      error ->
        Logger.warn(fn ->
          "Message on NATS topic #{inspect(message.topic)} is not a CloudEvent (#{inspect(error)}). The message: #{
            inspect(message)
          }"
        end)
    end
  end
end
