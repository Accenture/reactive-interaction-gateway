defmodule CloudEvents.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :cloud_events,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Encode/decode to/from JSON:
      {:jason, "~> 1.1"},
      # Auto-fill eventTime:
      {:timex, "~> 3.4"},
      # Auto-fill eventID:
      {:uuid, "~> 1.1"}
    ]
  end
end
