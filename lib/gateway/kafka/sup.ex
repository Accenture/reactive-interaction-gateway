defmodule Gateway.Kafka.Sup do
  @moduledoc """
  Supervisor handling Kafka-related processes.

  Also see `Gateway.Kafka.SupWrapper`.
  """
  @behaviour :supervisor3
  require Logger

  @brod_client_id Application.fetch_env!(:gateway, :kafka_client_id)

  def start_link do
    :supervisor3.start_link(
      _sup_name = {:local, __MODULE__},
      _module = __MODULE__,
      _args = :ok
    )
  end

  @impl :supervisor3
  def init(:ok) do
    brokers = fetch_kafka_broker_list()
    client_conf = [
      auto_start_producers: true,
      default_producer_config: []
    ]
    Logger.debug("""
    Starting brod_client
      id=#{inspect @brod_client_id}
      brokers=#{inspect brokers}
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
          child_spec(:brod_client, :worker, [brokers, @brod_client_id, client_conf]),
          child_spec(Gateway.Kafka.GroupSubscriber, :worker, []),
        ]
      }
    }
  end

  @impl :supervisor3
  def post_init(_) do
    :ignore
  end

  @spec fetch_kafka_broker_list() :: keyword(pos_integer())
  defp fetch_kafka_broker_list do
    # Allow for defining the Kafka brokers using an environment variable:
    case System.get_env("KAFKA_HOSTS") do
      nil -> Application.fetch_env!(:gateway, :kafka_broker_csv_list)
      csv -> csv
    end
    |> parse_broker_csv
  end

  @spec parse_broker_csv(String.t) :: keyword(pos_integer())
  defp parse_broker_csv(brokers) do
    brokers
    |> String.split(",")
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
