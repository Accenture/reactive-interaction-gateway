defmodule RigMesh.Mixfile do
  use Mix.Project

  def project do
    %{rig: rig_version, elixir: elixir_version} = versions()
    [
      app: :rig_mesh,
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
      mod: {RigMesh.Application, []}
    ]
  end

  defp versions do
    {map, []} = Code.eval_file("version", "../..")
    map
  end

  defp deps do
    [
      {:phoenix_pubsub, "~> 1.0"}
    ]
  end
end
