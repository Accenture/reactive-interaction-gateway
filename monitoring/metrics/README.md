# Metrics

Metrics are provided via [Prometheus](https://prometheus.io/) and dashboard via [Grafana](https://grafana.com/).

This example starts Kafka, Zookeeper, Jaeger, Prometheus, Grafana, Localstack, Kafkacat and RIG. Once it's running perform this tasks:

- send 1 correct Kafka event every second
- send 1 correct Kinesis event every 5 seconds
- send 1 incorrect Kafka event every 30 seconds
- Blacklists 1 session every 30 seconds

To quickly start and play around run `./run.sh`. It will take couple of minutes for the first time as it needs to download all the images. Once it's running you can create couple of connections/subscriptions via:

```bash
http --stream :4000/\_rig/v1/connection/sse?subscriptions=[{\"eventType\":\"greeting.foo\"}]
```
