defmodule RigTests.MixProject do
  @moduledoc false
  use Mix.Project

  alias Rig.Umbrella.Mixfile, as: Umbrella

  def project do
    [
      app: :rig_tests,
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

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rig_api, in_umbrella: true},
      {:rig_inbound_gateway, in_umbrella: true},
      {:rig_kafka, in_umbrella: true}
    ]
  end
end
