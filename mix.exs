defmodule Rig.Umbrella.Mixfile do
  @moduledoc false
  use Mix.Project

  def project do
    %{elixir: elixir_version, rig: rig_version} = versions()

    [
      apps_path: "apps",
      name: "Reactive Interaction Gateway",
      description: description(),
      version: rig_version,
      source_url: "https://github.com/Accenture/reactive-interaction-gateway",
      homepage_url: "https://accenture.github.io/reactive-interaction-gateway",
      docs: docs(),
      # hex.pm doesn't support umbrella projects
      package: package(),
      elixir: elixir_version,
      compilers: [:phoenix] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp versions do
    {map, []} = Code.eval_file("version", ".")
    map
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:distillery, "~> 2.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false}
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
      organization: "Accenture",
      maintainers: ["Kevin Bader", "Mario Macai"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/Accenture/reactive-interaction-gateway"}
    ]
  end

  defp docs do
    [
      main: "api-reference",
      output: "website/static/reference",
      extras: [
        "CHANGELOG.md": [title: "Changelog"]
      ]
    ]
  end
end
