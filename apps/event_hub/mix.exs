defmodule EventHub.Mixfile do
  use Mix.Project

  def project do
    [app: :event_hub,
     version: "0.1.0",
     elixir: "~> 1.7.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger],
      mod: {EventHub.Application, []}]
  end

  defp deps do
    [
      {:ace, "~> 0.16.4"},
      {:phoenix_html, "~> 2.11"},
      {:raxx_api_blueprint, "~> 0.1.0"},
      {:raxx_static, "~> 0.6.1"},
      {:exsync, "~> 0.2.3", only: :dev},
    ]
  end
end
