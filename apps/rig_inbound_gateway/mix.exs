defmodule RigInboundGateway.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    %{rig: rig_version, elixir: elixir_version} = versions()

    [
      app: :rig_inbound_gateway,
      version: rig_version,
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: elixir_version,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
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
      mod: {RigInboundGateway.Application, []},
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
      {:rig_cloud_events, in_umbrella: true},
      {:rig, in_umbrella: true},
      {:rig_auth, in_umbrella: true},
      {:rig_kafka, in_umbrella: true},
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:httpoison, "~> 1.3"},
      # JSON libs:
      {:poison, "~> 3.0 or ~> 4.0"},
      {:jason, "~> 1.1"},
      # Date and time handling:
      {:timex, "~> 3.4"},
      # Helper to make writing stubs and mocks easier:
      {:stubr, "~> 1.5.0", only: :test},
      # Elixir-compatible :ets.fun2ms/1
      {:ex2ms, "~> 1.0"},
      # Read and use application configuration from environment variables
      {:confex, "~> 3.3"},
      {:uuid, "~> 1.1"},
      # SSE serialization:
      {:server_sent_event, "~> 0.4.6"},
      # AWS SDK
      {:ex_aws, "~> 2.0"},
      {:ex_aws_kinesis, "~> 2.0"},
      # For backend service mocks:
      {:fake_server,
       github: "bernardolins/fake_server",
       ref: "4e0a1c2a8ea0fa9b5ab72b5cab063458ce0b447d",
       only: :test},
      {:socket, "~> 0.3", only: :test},
      {:joken, "~> 1.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    []
  end
end
