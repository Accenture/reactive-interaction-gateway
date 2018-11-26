defmodule RigKafka.MixProject do
  @moduledoc false
  use Mix.Project

  alias Rig.Umbrella.Mixfile, as: Umbrella

  def project do
    [
      app: :rig_kafka,
      version: Umbrella.release_version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: Umbrella.elixir_version(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RigKafka.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # The Kafka client:
      {:brod, "~> 3.7"},
      # For Kafka, partition from MurmurHash(key):
      {:murmur, "~> 1.0"},
      # For generating client_id and group_id:
      {:uuid, "~> 1.1"}
    ]
  end
end
