defmodule Gateway.Kafka.Sup do
  @moduledoc """
  Supervisor handling Kafka-related processes.

  Also see `Gateway.Kafka.SupWrapper`.
  """
  @behaviour :supervisor3
  use Gateway.Config, :custom_validation
  require Logger

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
    Logger.debug("""
    Starting brod_client
      id=#{inspect conf.brod_client_id}
      brokers=#{inspect conf.brokers}
      config=#{inspect client_conf}
    """)
    {
      :ok,
      {
        _restart_strategy = {
          :rest_for_one,
          _max_restarts = 0,  # always use delay for retries
          _max_time = 1,
        },
        _children = [
          child_spec(:brod_client, :worker, [conf.brokers, conf.brod_client_id, client_conf]),
          child_spec(Gateway.Kafka.GroupSubscriber, :worker, []),
        ]
      }
    }
  end

  @impl :supervisor3
  def post_init(_) do
    :ignore
  end

  # Confex callback
  defp validate_config!(config) do
    %{
      brod_client_id: config |> Keyword.fetch!(:brod_client_id),
      brokers: config |> Keyword.fetch!(:hosts) |> parse_hosts,
    }
  end

  @spec parse_hosts([String.t, ...]) :: keyword(pos_integer())
  defp parse_hosts(hosts) do
    hosts
    |> Enum.map(fn(broker) ->
      [host, port] = String.split(broker, ":")
      {String.to_atom(host), String.to_integer(port)}
    end)
  end

  defp child_spec(module, type, args) do
    {
      _id = module,
      _start_func = {
        _mod = module,
        _func = :start_link,
        _args = args
      },
      _restart = {
        _strategy = :permanent,
        _delay_s = 10
      },
      _shutdown = 5000,  # timeout (or :brutal_kill)
      type,
      _modules = [module]
    }
  end
end
