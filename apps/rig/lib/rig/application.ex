defmodule Rig.Application do
  @moduledoc false

  use Application
  use Rig.Config, [:log_level]
  use Supervisor

  alias RigOutboundGateway.Kinesis
  alias RigOutboundGateway.KinesisFirehose

  def start(_type, _args) do
    alias Supervisor.Spec

    # Override application logging with environment variable
    Logger.configure([{:level, config().log_level}])

    Rig.Discovery.start()

    children = [
      Spec.supervisor(Phoenix.PubSub.PG2, [Rig.PubSub, []]),
      Rig.EventFilter.Sup,
      Rig.EventStream.KafkaToFilter,
      Rig.EventStream.KafkaToHttp,
      RigApi.Endpoint,
      worker(Rig.DistributedSet, _args = [SessionBlacklist, [name: SessionBlacklist]]),
      Kinesis.JavaClient,
      KinesisFirehose.JavaClient
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

  # Phoenix callback for RigApi
  def config_change(changed, _new, removed) do
    RigApi.Endpoint.config_change(changed, removed)
    :ok
  end
end
