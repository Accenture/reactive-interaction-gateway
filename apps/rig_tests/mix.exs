defmodule RigTests.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :rig_tests,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp deps do
    [
      {:rig_api, in_umbrella: true},
      {:rig_inbound_gateway, in_umbrella: true},
      {:rig_kafka, in_umbrella: true},
      {:fake_server, "~> 2.0", only: :test}
    ]
  end
end
