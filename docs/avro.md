---
id: avro
title: Avro Implementation Details
sidebar_label: Avro
---

Apache Avro format as adapted by the [Confluent Schema Registry](https://docs.confluent.io/current/schema-registry/docs/serializer-formatter.html#wire-format):

```bash
# 0 - magic byte
# 1-4 - schema id - this is used by consumer to know which schema to use for deserialization
# 5-... - data

# Example
<0, 0, 0, 0, 1, 5, 3, 8, ...>
```

## Overview

![event-serialization-avro](assets/event-serialization-avro.png)

Adopting Avro for event (de)serialization is fairly straightforward. First you need to run an instance of the `Kafka Schema Registry`, which is a central store for all Avro schemas in use. As an event is consumed from Kafka, RIG fetches the corresponding schema from the registry and deserializes the event with it, caching the schema in the process (in memory). As for producing, RIG again retrieves and caches the schemas used for serializing events.

## RIG as a Kafka producer

- producer evaluates if serialization is turned on by checking `KAFKA_SERIALIZER` environment variable and if it's value is `avro`
- If it is, creates headers for Kafka event by appending `ce-` prefix for every field, besides `data` field
  - **nested context attributes are stringified**, since Kafka headers don't support nested values (this is common when using Cloud events extensions)
- after that, the `data` field is serialized using the schema name (function for getting schemas from registry is cached in-memory)
- producer sends event with created headers and data (in binary format `<<0, 0, 0, 0, 1, 5, 3, 8, ...>>`) to Kafka

> If `KAFKA_SERIALIZER` is not set to `avro`, producer sets **only** `ce-contenttype` or `ce-contentType` for kafka event

## RIG as a Kafka consumer

Event parsing is based on the [Kafka Transport Binding for CloudEvents v1.0](https://github.com/cloudevents/spec/blob/v1.0/kafka-protocol-binding.md). Check the [Event format](./event-format.md#kafka-transport-binding) section.

## Example 1: producing to and consuming from the same topic

In this example we'll have RIG send a message to itself to see whether RIG producing and consuming parts work correctly. The idea is that RIG produces a serialized event as a result to an HTTP request and, a few moments later, consumes that same event (and deserializes it correctly).

```bash
## 1. Start Kafka with Zookeeper and Kafka Schema Registry
KAFKA_PORT_PLAIN=17092 KAFKA_PORT_SSL=17093 HOST=localhost docker-compose -f integration_tests/kafka_tests/docker-compose.yml up -d

## 2. Start Rig
# Here we say to use Avro, consume on topic "rigRequest" and use "rigRequest-value" schema from Kafka Schema Registry
# Proxy is turned on to be able to produce Kafka event with headers (needed for cloud events)
docker run --name rig \
-e KAFKA_BROKERS=kafka:9292 \
-e KAFKA_SERIALIZER=avro \
-e KAFKA_SCHEMA_REGISTRY_HOST=kafka-schema-registry:8081 \
-e KAFKA_SOURCE_TOPICS=rigRequest \
-e PROXY_CONFIG_FILE=proxy/proxy.test.json \
-e PROXY_KAFKA_REQUEST_TOPIC=rigRequest \
-e PROXY_KAFKA_REQUEST_AVRO=rigRequest-value \
-e LOG_LEVEL=debug \
-p 4000:4000 -p 4010:4010 \
--network kafka_tests_default \
accenture/reactive-interaction-gateway

## 3. Register Avro schema in Kafka Schema Registry
curl -d '{"schema":"{\"name\":\"rigproducer\",\"type\":\"record\",\"fields\":[{\"name\":\"example\",\"type\":\"string\"}]}"}' -H "Content-Type: application/vnd.schemaregistry.v1+json" -X POST http://localhost:8081/subjects/rigRequest-value/versions

## 4. Send HTTP request to RIG proxy
# Request will produce serialized Kafka event to Kafka
curl -d '{"event":{"id":"069711bf-3946-4661-984f-c667657b8d85","type":"com.example","time":"2018-04-05T17:31:00Z","specversion":"0.2","source":"\/cli","contenttype":"avro\/binary","data":{"example":"test"}},"partition":"test_key"}' -H "Content-Type: application/json" -X POST http://localhost:4000/myapi/publish-async

## 5. In terminal you should see something like below -- in nutshell it means event was successfully consumed, deserialized and forwarded to UI client
16:46:31.549 [debug] Decoded Avro message="{\"example\":\"test\"}"
application=rig_kafka module=RigKafka.Avro function=decode/1 file=lib/rig_kafka/avro.ex line=28 pid=<0.419.0>

16:46:31.550 [debug] [:start_object, {:string, "contenttype"}, :colon, {:string, "avro/binary"}, :comma, {:string, "data"}, :colon, :start_object, {:string, "example"}, :colon, {:string, "test"}, :end_object, :comma, {:string, "id"}, :colon, {:string, "069711bf-3946-4661-984f-c667657b8d85"}, :comma, {:string, "rig"}, :colon, :start_object, {:string, "correlation"}, :colon, {:string, "g2dkAA1ub25vZGVAbm9ob3N0AAADzAAAAAAA"}, :comma, {:string, "headers"}, :colon, :start_array, :start_array, {:string, "accept"}, :end_array, :comma, :start_array, {:string, "*/*"}, :end_array, :comma, :start_array, {:string, "content-length"}, :end_array, :comma, :start_array, {:string, "221"}, :end_array, :comma, :start_array, {:string, "content-type"}, :end_array, :comma, :start_array, {:string, ...}, :end_array, ...]
application=rig module=Rig.EventStream.KafkaToFilter function=kafka_handler/1 file=lib/rig/event_stream/kafka_to_filter.ex line=20 pid=<0.419.0>
```

## Example 2: Kafka schema Registry CLI

To check if it works also with native serializer we can leverage the CLI shipped with the Kafka Schema Registry image.

```bash
# 1. Get inside Kafka Schema Registry container
docker exec -it kafka-schema-registry bash

# 2. Start native consumer with Avro
kafka-avro-console-consumer --topic rigRequest \
--bootstrap-server kafka:9292 \
--property schema.registry.url='http://kafka-schema-registry:8081'

# 3. Send HTTP request to RIG proxy - same request as before
curl -d '{"event":{"id":"069711bf-3946-4661-984f-c667657b8d85","type":"com.example","time":"2018-04-05T17:31:00Z","specversion":"0.2","source":"\/cli","contenttype":"avro\/binary","data":{"example":"test"}},"partition":"test_key"}' -H "Content-Type: application/json" -X POST http://localhost:4000/myapi/publish-async

# 4. Now there should be message also in this consumer
{"example":"test"}
```
