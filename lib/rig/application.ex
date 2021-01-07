defmodule Rig.Application do
  @moduledoc false

  use Application
  use Rig.Config, [:log_level, :log_fmt, :schema_registry_host]

  alias RIG.Discovery
  alias RIG.Tracing
  alias RigOutboundGateway.Kinesis

  alias LoggerJSON.Formatters.BasicLogger

  def start(_type, _args) do
    alias Supervisor.Spec

    setup_logger()

    Tracing.start()
    Discovery.start()

    children = [
      {Phoenix.PubSub, name: Rig.PubSub},
      # Kafka:
      {DynamicSupervisor, strategy: :one_for_one, name: RigKafka.DynamicSupervisor},
      # Event stream handling:
      Rig.EventFilter.Sup,
      Rig.EventStream.KafkaToFilter,
      Rig.EventStream.NatsToFilter,
      # Blacklist:
      Spec.worker(RIG.DistributedSet, _args = [SessionBlacklist, [name: SessionBlacklist]]),
      # Kinesis event stream:
      Kinesis.JavaClient,
      # RIG API (internal port):
      RigApi.Endpoint,
      # Request logger for proxy:
      RigInboundGateway.RequestLogger.Kafka,
      # API proxy:
      RigInboundGateway.ApiProxy.Sup,
      RigInboundGateway.ApiProxy.Handler.Kafka,
      # RIG public-facing endpoint:
      RigInboundGatewayWeb.Endpoint,
      # Cloud Events:
      {Cloudevents, [confluent_schema_registry_url: config().schema_registry_host]}
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

  defp setup_logger do
    conf = config()
    level = conf.log_level |> String.downcase() |> String.to_atom()
    format = conf.log_fmt |> String.downcase()

    # Override application logging with environment variable
    Logger.configure([{:level, level}])
    setup_logger_backend(format)
  end

  defp setup_logger_backend(format)

  defp setup_logger_backend("json") do
    Logger.add_backend(LoggerJSON)

    Logger.configure_backend(LoggerJSON,
      formatter: LoggerJSON.Formatters.BasicLogger,
      metadata: :all
    )
  end

  # Google Cloud Logger format
  defp setup_logger_backend("gcl") do
    Logger.add_backend(LoggerJSON)

    Logger.configure_backend(LoggerJSON,
      formatter: LoggerJSON.Formatters.GoogleCloudLogger,
      metadata: :all
    )
  end

  defp setup_logger_backend("erlang") do
    Logger.add_backend(:console)
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
