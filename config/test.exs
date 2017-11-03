use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gateway, GatewayWeb.Endpoint,
  env: :test,
  http: [port: System.get_env("PORT") || 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Proxy test route config file location
config :gateway, proxy_config_file: "proxy/proxy.test.json"

config :gateway, proxy_rate_limit_enabled?: true
config :gateway, proxy_rate_limit_sweep_interval_ms: 0
config :gateway, kafka_enabled?: false

config :gateway, :gateway_proxy, Gateway.ProxyMock
