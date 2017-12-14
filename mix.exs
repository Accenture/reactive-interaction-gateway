defmodule Rig.Umbrella.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      description: description(),
      docs: docs(),
      package: package(),  # hex.pm doesn't support umbrella projects
      elixir: "~> 1.5",
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

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:excoveralls, "~> 0.6.2", only: [:dev, :test]},
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:distillery, "~> 1.4"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
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
    ]
  end

  defp docs do
    [
      name: "Reactive Interaction Gateway",
      source_url: "https://github.com/Accenture/reactive-interaction-gateway",
      homepage_url: "https://github.com/Accenture/reactive-interaction-gateway",
      #homepage_url: "https://accenture.github.io/reactive-interaction-gateway",
      main: "motivation",
      extras: [
        "README.md": [title: "README"],
        "guides/motivation.md": [title: "Why we built it"],
        "guides/configuration.md": [title: "Configuration"],
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "guides/architecture/decisions/0001-record-architecture-decisions.md": [group: "Architecture Decisions"],
        "guides/architecture/decisions/0002-don-t-check-for-functionclauseerror-in-tests.md": [group: "Architecture Decisions"],
        "guides/architecture/decisions/0004-use-rig-config-for-global-configuration.md": [group: "Architecture Decisions"],
      ],
    ]
  end
end
