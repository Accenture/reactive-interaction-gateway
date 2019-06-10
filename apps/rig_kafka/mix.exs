defmodule RigKafka.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    %{rig: rig_version, elixir: elixir_version} = versions()

    [
      app: :rig_kafka,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RigKafka.Application, []}
    ]
  end

  defp versions do
    {map, []} = Code.eval_file("version", "../..")
    map
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # The Kafka client:
      {:brod, "~> 3.7"},
      # For Kafka, partition from MurmurHash(key):
      {:murmur, "~> 1.0"},
      # Apache Avro encoding/decoding library:
      {:erlavro, "~> 2.6.3"},
      # Apache Kafka Schema Registry wrapper library:
      {:schemex, "~> 0.1.1"},
      # Caching library using ETS:
      {:memoize, "~> 1.3"},
      {:fake_server, "~> 2.0", only: :test},
      # For generating client_id:
      {:uuid, "~> 1.1"},
      # JSON parser:
      {:jason, "~> 1.1"}
    ]
  end
end
