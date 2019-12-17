defmodule Rig.Application do
  @moduledoc false

  use Application
  use Rig.Config, [:log_level]

  alias RigOutboundGateway.Kinesis
  alias RigOutboundGateway.KinesisFirehose

  def start(_type, _args) do
    alias Supervisor.Spec

    # Override application logging with environment variable
    Logger.configure([{:level, config().log_level}])

    Rig.Discovery.start()

    children = [
      Spec.supervisor(Phoenix.PubSub.PG2, [Rig.PubSub, []]),
      # Kafka:
      {DynamicSupervisor, strategy: :one_for_one, name: RigKafka.DynamicSupervisor},
      # Event stream handling:
      Rig.EventFilter.Sup,
      Rig.EventStream.KafkaToFilter,
      Rig.EventStream.KafkaToHttp,
      # Blacklist:
      Spec.worker(RIG.DistributedSet, _args = [SessionBlacklist, [name: SessionBlacklist]]),
      #Metadata:
      Spec.worker(RIG.DistributedMap, _args = [:metadata, [name: :metadata]]),
      # Kinesis event stream:
      Kinesis.JavaClient,
      KinesisFirehose.JavaClient,
      # RIG API (internal port):
      RigApi.Endpoint,
      # Request logger for proxy:
      RigInboundGateway.RequestLogger.Kafka,
      # API proxy:
      RigInboundGateway.ApiProxy.Sup,
      RigInboundGateway.ApiProxy.Handler.Kafka,
      # RIG public-facing endpoint:
      RigInboundGatewayWeb.Endpoint
    ]

    # Prometheus
    # TODO: setup currently commented out, as metrics are not yet implemented and
    # therefore shouldn't be exposed yet to the endpoint

    # RigMetrics.ControlInstrumenter.setup()
    # RigMetrics.EventhubInstrumenter.setup()
    RigMetrics.ProxyMetrics.setup()
    RigMetrics.MetricsPlugExporter.setup()

    opts = [strategy: :one_for_one, name: Rig.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  This function is called by an application after a code replacement, if the configuration parameters have changed.

  Changed is a list of parameter-value tuples including all configuration parameters with changed values.

  New is a list of parameter-value tuples including all added configuration parameters.

  Removed is a list of all removed parameters.
  """
  def config_change(changed, _new, removed) do
    RigApi.Endpoint.config_change(changed, removed)
    RigInboundGatewayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
