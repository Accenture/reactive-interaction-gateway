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
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rig_api, in_umbrella: true},
      {:rig_inbound_gateway, in_umbrella: true},
      {:rig_kafka, in_umbrella: true},
      {:fake_server,
       github: "bernardolins/fake_server",
       ref: "4e0a1c2a8ea0fa9b5ab72b5cab063458ce0b447d",
       only: :test}
    ]
  end
end
