defmodule RigOutboundGateway.Kafka.Sup do
  @moduledoc """
  Supervisor handling Kafka-related processes.

  ## About the Kafka Integration

  In order to scale horizontally,
  [Kafka Consumer Groups](https://kafka.apache.org/documentation/#distributionimpl)
  are used. This supervisor takes care of the [Brod](https://github.com/klarna/brod)
  client -- Brod is the library used for communicating with Kafka --, which holds the
  connection to one of the Kafka brokers. Brod also relies on a worker process called
  GroupSubscriber, which is also managed by the supervisor at hand.

  The consumer setup is done in `Rig.Kafka.GroupSubscriber`; take a look at its
  moduledoc for more information. Finally, `Rig.Kafka.MessageHandler` hosts the
  code for the actual processing of incoming messages.

  Note that this supervisor is not a classical OTP supervisor: in case one of the
  restart limits is reached, it doesn't simply die, like an OTP supervisor would.
  Instead, it waits for some fixed delay, resets itself and tries again. This enables
  us to stay alive even if the connection to Kafka breaks down, without filling up the
  log files too quickly.

  """
  @behaviour :supervisor3
  use Rig.Config, :custom_validation
  require Logger

  alias RigOutboundGateway.Kafka.GroupSubscriber

  def start_link do
    :supervisor3.start_link(
      _sup_name = {:local, __MODULE__},
      _module = __MODULE__,
      _args = :ok
    )
  end

  @impl :supervisor3
  def init(:ok) do
    conf = config()

    client_conf = [
      auto_start_producers: true,
      default_producer_config: []
    ]

    Logger.info("""
    Starting brod_client
      id=#{inspect(conf.brod_client_id)}
      brokers=#{inspect(conf.brokers)}
      config=#{inspect(client_conf)}
    """)

    restart_strategy = {:rest_for_one, _max_restarts = 1, _max_time = 10}

    children = [
      child_spec(:brod_client, :worker, [conf.brokers, conf.brod_client_id, client_conf]),
      child_spec(GroupSubscriber, :worker, [])
    ]

    {:ok, {restart_strategy, children}}
  end

  @impl :supervisor3
  def post_init(_) do
    :ignore
  end

  # Confex callback
  defp validate_config!(config) do
    %{
      brod_client_id: config |> Keyword.fetch!(:brod_client_id),
      brokers: config |> Keyword.fetch!(:hosts) |> parse_hosts
    }
  end

  @spec parse_hosts([String.t(), ...]) :: keyword(pos_integer())
  defp parse_hosts(hosts) do
    hosts
    |> Enum.map(fn broker ->
         [host, port] = String.split(broker, ":")
         {String.to_atom(host), String.to_integer(port)}
       end)
  end

  defp child_spec(module, type, args) do
    {
      _id = module,
      _start_func =
        {
          _mod = module,
          _func = :start_link,
          _args = args
        },
      _restart =
        {
          _strategy = :permanent,
          _delay_s = 20
        },
      # timeout (or :brutal_kill)
      _shutdown = 5000,
      type,
      _modules = [module]
    }
  end
end
