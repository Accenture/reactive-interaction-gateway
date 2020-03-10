defmodule RIG.MixProject do
  @moduledoc false
  use Mix.Project

  @description """
  RIG, the Reactive Interaction Gateway, provides an easy (and scaleable) way to push messages
  from backend services to connected frontends (and vice versa).
  """

  def project do
    %{rig: rig_version, elixir: elixir_version} = versions()

    [
      # OTP app:
      app: :rig,

      # Meta data:
      name: "Reactive Interaction Gateway",
      description: @description,
      version: rig_version,
      source_url: "https://github.com/Accenture/reactive-interaction-gateway",
      homepage_url: "https://accenture.github.io/reactive-interaction-gateway",
      docs: docs(),
      package: package(),

      # Build:
      elixir: elixir_version,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers() ++ [:phoenix_swagger],

      # Test and test coverage:
      test_paths: test_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(_), do: ["lib", "test"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Rig.Application, []},
      extra_applications: [:logger, :runtime_tools, :prometheus_ex, :prometheus_plugs],
      included_applications: [:peerage]
    ]
  end

  defp versions do
    {map, []} = Code.eval_file("version", ".")
    map
  end

  defp docs do
    [
      # Website and documentation is built off master,
      # so that's where we should link to:
      source_ref: "master",
      main: "api-reference",
      output: "website/static/source_docs",
      extras: [
        "CHANGELOG.md": [title: "Changelog"]
      ]
    ]
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Test coverage reporting:
      {:excoveralls, "~> 0.10", only: :test, runtime: false},
      # Linting:
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      # Static type checks:
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      # OTP releases:
      {:distillery, "~> 2.1", runtime: false},
      # Documentation generator:
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      # Automatically run tests on file changes:
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      # Read and use application configuration from environment variables:
      {:confex, "~> 3.3"},
      # For providing the global Phx PubSub server:
      {:phoenix_pubsub, "~> 1.0"},
      # for Kafka, partition from MurmurHash(key):
      {:murmur, "~> 1.0"},
      {:peerage, "~> 1.0"},
      # For running external commands in Mix tasks:
      {:porcelain, "~> 2.0"},
      # HTTP request handling (wraps Cowboy):
      {:plug, "~> 1.4"},
      # JSON parser, for cloud_event and event_hub:
      {:poison, "~> 3.0 or ~> 4.0"},
      # JSON parser that's supposedly faster than poison:
      {:jason, "~> 1.1"},
      {:jaxon, "~> 1.0"},
      # JSON Pointer (RFC 6901) implementation for subscriptions:
      {:odgn_json_pointer, "~> 2.3"},
      # Apache Kafka Erlang client library:
      {:brod, "~> 3.3"},
      # Apache Avro encoding/decoding library:
      {:erlavro, "~> 2.6"},
      # Apache Kafka Schema Registry wrapper library:
      {:schemex, "~> 0.1.1"},
      # Caching library using ETS:
      {:memoize, "~> 1.3"},
      # For distributed_set:
      {:timex, "~> 3.6"},
      {:ex2ms, "~> 1.5"},
      {:uuid, "~> 1.1"},
      # For doing HTTP requests, e.g., in kafka_as_http:
      {:httpoison, "~> 1.3"},
      # For property-based testing:
      {:stream_data, "~> 0.1", only: :test},
      # For JSON Web Tokens:
      {:joken, "~> 1.5"},
      # Web framework, for all HTTP endpoints except SSE and WS:
      {:phoenix, "~> 1.4"},
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_swagger, "~> 0.8"},
      # SSE serialization:
      {:server_sent_event, "~> 1.0"},
      # A library for defining structs with a type without writing boilerplate code:
      {:typed_struct, "~> 0.1.4"},
      # AWS SDK
      {:ex_aws, "~> 2.0"},
      {:ex_aws_kinesis, "~> 2.0"},
      # Mock library for testing:
      {:mox, "~> 0.4", only: :test},
      {:stubr, "~> 1.5.0", only: :test},
      {:fake_server, "~> 2.0", only: :test},
      {:socket, "~> 0.3", only: :test},
      # Prometheus metrics
      {:prometheus_ex, "~> 3.0"},
      {:prometheus_plugs, "~> 1.1"},
      {:opencensus_plug, "~> 0.3"}
    ]
  end

  defp aliases do
    [
      compile: ["compile", "update_docs"]
    ]
  end
end
