# Metrics

Metrics are provided via [Prometheus](https://prometheus.io/) and dashboard via [Grafana](https://grafana.com/).

To quickly start and play around run `./run.sh`. It will take couple of minutes for the first time as it needs to download all the images. Once it's running you can create couple of connections/subscriptions via:

```bash
http --stream :4000/\_rig/v1/connection/sse?subscriptions=[{\"eventType\":\"greeting.simple\"}]
```

Script itself sends 1 request per second to RIG proxy to produce a Kafka event. Every 30 seconds blacklists 1 session and sends 1 invalid event via Kafkacat.
