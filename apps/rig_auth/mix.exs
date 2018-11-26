defmodule RigAuth.Mixfile do
  @moduledoc false
  use Mix.Project

  alias Rig.Umbrella.Mixfile, as: Umbrella

  def project do
    [
      app: :rig_auth,
      version: Umbrella.release_version(),
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: Umbrella.elixir_version(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {RigAuth.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rig, in_umbrella: true},
      {:confex, "~> 3.3"},
      {:cowboy, "~> 1.0"},
      {:httpoison, "~> 1.3"},
      {:joken, "~> 1.5"},
      {:phoenix, "~> 1.3.0"},
      {:plug, "~> 1.4"},
      {:poison, "~> 2.0 or ~> 3.0"},
      {:stubr, "~> 1.5.0", only: :test},
      {:timex, "~> 3.1.22"},
      # JSON Pointer (RFC 6901) implementation for extracting the session name from JWTs:
      {:odgn_json_pointer, "~> 2.3"}
    ]
  end
end
