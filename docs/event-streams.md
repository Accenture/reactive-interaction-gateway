---
id: event-streams
title: Event Streams
sidebar_label: Event Streams
---

Real time part of RIG is driven by events (Kafka/Kinesis) -- to make it work there is some configuration required.

Where is RIG using event streams:

- publishing via API Gateway to specific topic/stream, see [Publishing to event streams](./api-gateway#publishing-to-event-streams) for more details
  - consuming of events from specific topic/stream to achieve sync requests
- consuming of events to be forwarded via SSE/WS
- publishing "monitoring" messages per API Gateway call

Event stream functionality is by default disabled -- can be controlled via environment variables. All possible configuration can be found in [Operator's Guide](./rig-ops-guide.md)

## Kafka

### Enable Kafka

Kafka will be automatically enabled as soon as you set `KAFKA_BROKERS` environment variable.

```bash
# Kafka disabled
docker run accenture/reactive-interaction-gateway

# Kafka enabled
docker run -e KAFKA_BROKERS=kafka:9092 accenture/reactive-interaction-gateway
```

> __NOTE:__ it's enough to set one Kafka broker, RIG will automatically discover rest of the Kafka cluster.

### Change consumer topics and group ID

As Kafka is enabled, RIG starts to consume events on 2 default topics `rig` and `rig-proxy-response`. `rig` topic is used to consume all events and forward them to client via SSE/WS. `rig-proxy-response` is used for HTTP sync publishing, see [API Gateway docs](./api-gateway#sync).

Change topics:

```bash
# Single topic
docker run \
-e KAFKA_BROKERS=kafka:9092 \
-e KAFKA_SOURCE_TOPICS=my-topic \
-e PROXY_KAFKA_RESPONSE_TOPICS=my-proxy-topic \
accenture/reactive-interaction-gateway

# Multiple topics
docker run \
-e KAFKA_BROKERS=kafka:9092 \
-e KAFKA_SOURCE_TOPICS=my-topic1,my-topic2 \
-e PROXY_KAFKA_RESPONSE_TOPICS=my-proxy-topic1,my-proxy-topic2 \
accenture/reactive-interaction-gateway
```

In addition to topics you can configure also consumer group ID.
> __NOTE:__ same group ID will be used for all topics.

Change group ID:

```bash
docker run \
-e KAFKA_BROKERS=kafka:9092 \
-e KAFKA_SOURCE_TOPICS=my-topic \
-e PROXY_KAFKA_RESPONSE_TOPICS=my-proxy-topic \
-e KAFKA_GROUP_ID=my-group-id \
accenture/reactive-interaction-gateway
```

### Change producer topics

Rig can produce "monitoring" events as an HTTP endpoint is called in proxy and as a target of HTTP endpoint itself, see [API Gateway docs](./api-gateway#sync). Request are by default using `console` as an output.

Producing "monitoring" events as you call API Gateway endpoints is by default using `rig-request-log` topic.

Change topic:

```bash
docker run \
-e KAFKA_BROKERS=kafka:9092 \
-e REQUEST_LOG=console,kafka \
-e KAFKA_LOG_TOPIC=my-log-topic \
accenture/reactive-interaction-gateway
```

Producing events from proxy as a target of a request is by default disabled.

Change topic:

```bash
docker run \
-e KAFKA_BROKERS=kafka:9092 \
-e PROXY_KAFKA_REQUEST_TOPIC=my-proxy-request-topic \
accenture/reactive-interaction-gateway
```

### SSL

SSL for Kafka is by default disabled. To enable it and set certificates use following setup:

```bash
docker run \
-e KAFKA_BROKERS=kafka:9092 \
-e KAFKA_SSL_ENABLED=1 \
-e KAFKA_SSL_KEYFILE_PASS=abcdefgh \
accenture/reactive-interaction-gateway

# Change default paths for certificates
docker run \
-e KAFKA_BROKERS=kafka:9092 \
-e KAFKA_SSL_ENABLED=1 \
-e KAFKA_SSL_KEYFILE_PASS=abcdefgh \
-e KAFKA_SSL_CA_CERTFILE=my.ca.crt.pem \
-e KAFKA_SSL_CERTFILE=my.crt.pem \
-e KAFKA_SSL_KEYFILE=my.key.pem \
accenture/reactive-interaction-gateway
```

### SASL

SASL for Kafka is by default disabled. To enable it and set credentials use following setup:

```bash
docker run \
-e KAFKA_BROKERS=kafka:9092 \
-e KAFKA_SASL=plain:myusername:mypassword \
accenture/reactive-interaction-gateway
```

## Kinesis

### Enable Kinesis

Similar as Kafka, Kinesis is by default disabled and can be enabled via `KINESIS_ENABLED` environment variable.

```bash
# Kinesis disabled
docker run accenture/reactive-interaction-gateway

# Kinesis enabled
docker run -e KINESIS_ENABLED=1 accenture/reactive-interaction-gateway

# Configure AWS region
docker run -e KINESIS_ENABLED=1 -e KINESIS_AWS_REGION=eu-west-3 accenture/reactive-interaction-gateway
```

### Change consumer stream and app name

As Kinesis is enabled, RIG starts to consume events on default stream `RIG-outbound`. `RIG-outbound` topic is used to consume all events and forward them to client via SSE/WS.

Change stream:

```bash
docker run \
-e KINESIS_ENABLED=1 \
-e KINESIS_STREAM=my-stream \
accenture/reactive-interaction-gateway
```

In addition to stream, you can configure also app name. Kinesis is using value of `KINESIS_APP_NAME` as a name for DynamoDB table. DynamoDB is internally used to handle leases and consumer groups. It's similar to group ID in Kafka.

Change app name:

```bash
docker run \
-e KINESIS_ENABLED=1 \
-e KINESIS_STREAM=my-stream \
-e KINESIS_APP_NAME=my-app_name \
accenture/reactive-interaction-gateway
```

### Change producer streams

Rig can produce events as a target of HTTP endpoint call, see [API Gateway docs](./api-gateway#sync).

Producing events from proxy as a target of a request is by default disabled.

Change topic:

```bash
docker run \
-e KINESIS_ENABLED=1 \
-e PROXY_KINESIS_REQUEST_STREAM=my-proxy-request-topic \
-e PROXY_KINESIS_REQUEST_REGION=eu-west-3 \
accenture/reactive-interaction-gateway
```
