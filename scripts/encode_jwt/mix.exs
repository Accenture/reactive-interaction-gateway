defmodule EncodeJwt.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :encode_jwt,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def escript do
    [main_module: EncodeJwt]
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
      {:poison, "~> 2.0 or ~> 3.0"},
      {:joken, "~> 1.4"}
    ]
  end
end
