defmodule RigInboundGateway.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rig_inbound_gateway,
      version: "0.0.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {RigInboundGateway.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:rig, in_umbrella: true},
      {:rig_mesh, in_umbrella: true},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:cowboy, "~> 1.0"},
      {:httpoison, "~> 0.13.0"},
      {:joken, "~> 1.4"},
      {:bypass, "~> 0.8.1", only: :test},
      {:poison, "~> 2.0 or ~> 3.0"},
      {:timex, "~> 3.1.22"},
      {:stubr, "~> 1.5.0", only: :test},
      {:ex2ms, "~> 1.0"},  # Elixir-compatible :ets.fun2ms/1
      {:confex, "~> 3.3"},  # Read and use application configuration from environment variables
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
