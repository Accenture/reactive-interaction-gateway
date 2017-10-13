defmodule Gateway.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gateway,
      version: "0.0.1",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Gateway.Application, []},
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
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:httpoison, "~> 0.13.0"},
      {:joken, "~> 1.4"},
      {:bypass, "~> 0.8.1", only: :test},
      {:excoveralls, "~> 0.6.2", only: [:dev, :test]},
      {:brod, "~> 2.2"},
      {:supervisor3, "~> 1.1"},
      {:poison, "~> 2.0 or ~> 3.0"},
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:timex, "~> 3.1.22"},
      {:distillery, "~> 1.4"},
      {:stubr, "~> 1.5.0", only: :test},
      {:murmur, "~> 1.0"},  # for Kafka, partition from MurmurHash(key)
      {:uuid, "~> 1.1"},
      {:ex2ms, "~> 1.0"},  # Elixir-compatible :ets.fun2ms/1
      {:map_diff, "~> 1.3"},
    ]
  end
end
