---
id: azure-event-hubs
title: Azure Event Hubs
sidebar_label: Azure Event Hubs
---

[Azure Event Hubs](https://azure.microsoft.com/en-us/services/event-hubs/) is providing Kafka protocol and thus RIG can connect to it. However, it requires SASL and encrypted connection which might be a bit tricky to setup. This example should help to configure RIG properly.

```bash
KAFKA_SOURCE_TOPICS="rig" \
PROXY_KAFKA_RESPONSE_TOPICS="rig" \
KAFKA_BROKERS="<name>.servicebus.windows.net:9093" \
KAFKA_SSL_ENABLED=1 \
KAFKA_SSL_CA_CERTFILE=priv/ca.crt.pem \
KAFKA_SSL_CERTFILE= \
KAFKA_SSL_KEYFILE= \
KAFKA_SASL="plain:\$ConnectionString:Endpoint=..."
```

Important notes:

- enable SSL
  - enable `CA_CERTFILE` - you can use the `priv/ca.crt.pem` for testing, however should use your own in production
  - disable `CERTFILE` and `KEYFILE`
- note the `\` in the SASL username, otherwise it's stripped
