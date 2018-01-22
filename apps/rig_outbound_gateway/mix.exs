defmodule RigOutboundGateway.MixProject do
  use Mix.Project

  def project do
    %{rig: rig_version, elixir: elixir_version} = versions()
    [
      app: :rig_outbound_gateway,
      version: rig_version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: elixir_version,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RigOutboundGateway.Application, []}
    ]
  end

  defp versions do
    {map, []} = Code.eval_file("version", "../..")
    map
  end

  defp deps do
    [
      {:rig, in_umbrella: true},
      # Read and use application configuration from environment variables:
      {:confex, "~> 3.3"},
      # Apache Kafka Erlang client library:
      {:brod, "~> 3.3"},
      # JSON parser:
      {:poison, "~> 2.0 or ~> 3.0"},
      # Stubs and spies for tests:
      {:stubr, "~> 1.5"}
    ]
  end
end
