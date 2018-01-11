defmodule RigMesh.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rig_mesh,
      version: Rig.Umbrella.Mixfile.rig_version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: Rig.Umbrella.Mixfile.elixir_version(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RigMesh.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix_pubsub, "~> 1.0"}
    ]
  end
end
