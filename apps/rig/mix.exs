defmodule Rig.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    %{rig: rig_version, elixir: elixir_version} = versions()

    [
      app: :rig,
      version: rig_version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: elixir_version,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Rig.Application, []},
      extra_applications: [:logger],
      included_applications: [:peerage]
    ]
  end

  defp versions do
    {map, []} = Code.eval_file("version", "../..")
    map
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_pubsub, "~> 1.0"},
      # for Kafka, partition from MurmurHash(key):
      {:murmur, "~> 1.0"},
      {:peerage, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      compile: ["compile", "update_docs"]
    ]
  end
end
