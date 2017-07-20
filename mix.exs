defmodule Gateway.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gateway,
      version: "0.0.1",
      elixir: "~> 1.2",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
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
      mod: {Gateway, []},
      applications: [
        :phoenix,
        :phoenix_pubsub,
        :phoenix_html,
        :cowboy,
        :logger,
        :gettext,
        :httpoison,
        :timex,
        :terraform,
        :joken,
      ],
      included_applications: [
        :supervisor3,
        :brod,
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.2.1"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:httpoison, "~> 0.11.0"},
      {:terraform, "~> 1.0.1"},
      {:joken, "~> 1.4"},
      {:bypass, "~> 0.1", only: :test},
      {:excoveralls, "~> 0.6.2", only: [:dev, :test]},
      {:brod, "~> 2.2"},
      {:supervisor3, "~> 1.1"},
      {:poison, "~> 2.0 or ~> 3.0"},
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:timex, "~> 3.0"},
      {:distillery, "~> 1.4"},
      {:stubr, "~> 1.5.0", only: :test},
      {:murmur, "~> 1.0"},  # for Kafka, partition from MurmurHash(key)
    ]
  end
end
