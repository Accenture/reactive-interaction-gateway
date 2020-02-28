# Metrics

Metrics are provided via [Prometheus](https://prometheus.io/) and dashboards via [Grafana](https://grafana.com/).

TODO:

- wiki + docs
- produce fail + grafana
- blacklist specific distributed set
- labels
- kinesis

GRAFANA TODO:

- http latency metrics

histogram_quantile(0.95, sum(rate(rig_event_processing_duration_milliseconds_bucket[1m])) by (le))

http --stream :4000/\_rig/v1/connection/sse?subscriptions=[{\"eventType\":\"greeting.simple\"}]
