defmodule RigApi.Mixfile do
  use Mix.Project

  def project do
    %{rig: rig_version, elixir: elixir_version} = versions()

    [
      app: :rig_api,
      version: rig_version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: elixir_version,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers() ++ [:phoenix_swagger],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {RigApi.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp versions do
    {map, []} = Code.eval_file("version", "../..")
    map
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:cloud_events, in_umbrella: true},
      {:rig, in_umbrella: true},
      {:rig_inbound_gateway, in_umbrella: true},
      {:rig_outbound_gateway, in_umbrella: true},
      {:rig_auth, in_umbrella: true},
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:mox, "~> 0.4", only: :test},
      {:phoenix_swagger, "~> 0.8"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
