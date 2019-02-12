# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :rig_metrics, RigMetrics.Application,
  metrics_enabled?: {:system, :boolean, "METRICS_ENABLED", true}

import_config "#{Mix.env()}.exs"
