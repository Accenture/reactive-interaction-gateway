defmodule Gateway.Kafka.Sup do
  @moduledoc """
  Supervisor for all Kafka-related processes.
  """
  #use Supervisor
  @behaviour :supervisor3
  require Logger

  def start_link do
    :supervisor3.start_link(
      _sup_name = {:local, __MODULE__},
      _module = __MODULE__,
      _args = :ok
    )
  end

  # supervisor3 callback
  def init(:ok) do
    [{brod_client_id, endpoints: brokers}] = Application.fetch_env!(:brod, :clients)
    formatted_brokers = format_kafka_brokers(brokers)
    client_conf = {brod_client_id, [endpoints: formatted_brokers]}
    Logger.debug "brod_client config: id=#{inspect brod_client_id} brokers=#{inspect brokers}"
    {
      :ok,
      {
        _restart_strategy = {
          :rest_for_one,
          _max_restarts = 0,  # always use delay for retries
          _max_time = 1,
        },
        _children = [
          child_spec(:brod_client, :worker, [formatted_brokers, brod_client_id, [client_conf]]),
          child_spec(Gateway.Kafka.GroupSubscriber, :worker, []),
        ]
      }
    }
  end

  # supervisor3 callback
  def post_init(_) do
    :ignore
  end

  defp format_kafka_brokers(brokers) do
    brokers
    |> String.split(",")
    |> Enum.map(fn(broker) ->
      url = String.split(broker, ":")
      host = List.first(url) |> String.to_atom
      port = List.last(url) |> String.to_integer
      {host, port}
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
