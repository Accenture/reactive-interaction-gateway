defmodule Gateway.Mixfile do
  use Mix.Project

  # Must be a top-level folder in order not to break any relative links.
  @docs_output "doc.output"

  def project do
    [
      app: :gateway,
      name: "Reactive Interaction Gateway",
      version: "0.9.9",
      description: description(),
      package: package(),
      source_url: "https://github.com/Accenture/reactive-interaction-gateway",
      homepage_url: "https://accenture.github.io/reactive-interaction-gateway",
      docs: docs(),
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
      aliases: aliases(),
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
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:floki, "~> 0.18.1", runtime: false},  # HTML parser
      {:confex, "~> 3.3"},  # Read and use application configuration from environment variables
    ]
  end

  defp description do
    """
    RIG, the Reactive Interaction Gateway, provides an easy (and scaleable) way to push messages
    from backend services to connected frontends (and vice versa).
    """
  end

  defp package do
    [
      name: "rig",
      maintainers: ["Kevin Bader", "Mario Macai", "Martin Lofaj"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/Accenture/reactive-interaction-gateway"},
      files: ["lib", "priv", "mix.exs", "*.md", "LICENSE", "doc/configuration.md"],
    ]
  end

  defp docs do
    [
      output: @docs_output,
      extras: [
        "README.md": [title: "README"],
        "doc/motivation.md": [title: "Why we built it"],
        "doc/configuration.md": [title: "Configuration"],
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "doc/architecture/decisions/0001-record-architecture-decisions.md": [group: "Architecture Decisions"],
        "doc/architecture/decisions/0002-don-t-check-for-functionclauseerror-in-tests.md": [group: "Architecture Decisions"],
        "doc/architecture/decisions/0003-for-config-prefer-prefix-over-nesting-and-don-t-hide-defaults-in-code.md": [group: "Architecture Decisions"],
      ],
      main: "README",
    ]
  end

  defp aliases do
    [
      docs: ["docs", "docs.repair_links #{@docs_output}"],
    ]
  end
end
