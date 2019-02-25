---
id: event-serializing
title: Event Serializing
sidebar_label: Event Serializing
---

We support [Apache Avro](https://avro.apache.org/) and standard JSON (de)serialization of events for producer as well as for consumer. This is working together with [Cloud Events specification](https://github.com/cloudevents/spec)(versions `0.1` and `0.2`). To make both of these worlds work we are utilizing Kafka headers introduced in version `0.11`. As Cloud Events specify there are 2 modes how to make this combination work. Discussion about this topic can be followed on [Github](https://github.com/cloudevents/spec/pull/337/files).

**Structured content mode**

This mode should be used when JSON format is desired, thus no further serialization and deserialization such as Apache Avro is doing.

```bash
# <== KAFKA EVENT HEADERS ==>

cloudEvent_contentType: application/json

# <== KAFKA EVENT VALUE ==>

{
    "specversion" : "0.1",
    "type" : "com.example.someevent",
    "data": {},
    ...
}
```

**Binary content mode**

This mode should be used when further serialization and deserialization is desired (e.g. Apache Avro).

```bash
# <== KAFKA EVENT HEADERS ==>

cloudEvent_contentType: avro/binary
cloudEvent_specversion: "0.2"
cloudEvent_type: "com.example.someevent"
...

# <== KAFKA EVENT VALUE ==>

... application data ...
```

## Apache Avro format

To be compatible across the board Apache Avro is using specific format that needs to be followed.

```bash
# 0 - magic byte
# 1-4 - schema id - this is used by consumer to know which schema to use for deserialization
# 5-n - data

<0, 0, 0, 0, 1, 5, 3, 8, ...>
```

### Implementation

#### Setup

#### Producer

- producer evaluates if avro is turned on by checking `TODO` environment variable
- **IF** it's turned on creates headers for Kafka event by appending `cloudEvents_` prefix for every field besides `data` field
  - for deep nested values we are using query encoding since Kafka headers don't support nested values
- after that `data` field is serialized using the schema name (function for getting schemas from registry is cached)
- producer sends event with created headers and data (in binary format `<<0, 0, 0, 0, 1, 5, 3, 8, ...>>`) to Kafka

#### Consumer

- when consuming Kafka event RIG checks headers of this event and removes `cloudEvents_` prefix (TODO write test for this)
- based on headers decides cloud events version and content type
- **IF** content type is `avro/binary`, schema ID is taken from event value and deserialized
- **IF** if content type is **not** present checks for AVro format (`<<0, 0, 0, 0, 1, 5, 3, 8, ...>>`) and does deserialization

### Example

To quickly demonstrate if RIG is correctly (de)serializing events, we can leverage cli in Kafka Schema Registry.

```bash
# Start Kafka with Zookeeper and Kafka Schema Registry
cd integration_tests/kafka_tests
./run.sh

# Start Rig
cd ../../
KAFKA_BROKERS=localhost:9092 \
KAFKA_SERIALIZER=avro \
KAFKA_SOURCE_TOPICS=test2 \
PROXY_CONFIG_FILE=proxy/proxy.testx.json \
PROXY_KAFKA_REQUEST_TOPIC=test2 \
PROXY_KAFKA_REQUEST_AVRO=test2-value \
mix phx.server

# Create schema
{"schema":"{\"name\":\"myrecord\",\"type\":\"record\",\"fields\":[{\"name\":\"source\",\"type\":\"string\"},{\"name\":\"rig\",\"type\":{\"name\":\"rig\",\"type\":\"record\",\"fields\":[{\"name\":\"scheme\",\"type\":\"string\"},{\"name\":\"remoteip\",\"type\":\"string\"},{\"name\":\"query\",\"type\":\"string\"},{\"name\":\"port\",\"type\":\"int\"},{\"name\":\"path\",\"type\":\"string\"},{\"name\":\"method\",\"type\":\"string\"},{\"name\":\"host\",\"type\":\"string\"},{\"name\":\"headers\",\"type\":{\"type\":\"array\",\"items\":{\"type\":\"array\",\"items\":\"string\"}}},{\"name\":\"correlation\",\"type\":\"string\"}]}},{\"name\":\"extensions\",\"type\":{\"name\":\"extensions\",\"type\":\"record\",\"fields\":[]}},{\"name\":\"eventTypeVersion\",\"type\":\"string\"},{\"name\":\"eventType\",\"type\":\"string\"},{\"name\":\"eventTime\",\"type\":\"int\",\"logicalType\":\"date\"},{\"name\":\"eventID\",\"type\":\"string\"},{\"name\":\"data\",\"type\":{\"name\":\"data\",\"type\":\"record\",\"fields\":[{\"name\":\"foo\",\"type\":\"string\"}]}},{\"name\":\"contentType\",\"type\":\"string\"},{\"name\":\"cloudEventsVersion\",\"type\":\"string\"}]}"}

# Produce
kafka-avro-console-producer \
--broker-list rig-kafka:9092 --topic test2 \
--property schema.registry.url='http://rig-kafka-schema-registry:8081' \
--property value.schema='{"name":"myrecord","type":"record","fields":[{"name":"source","type":"string"},{"name":"rig","type":{"name":"rig","type":"record","fields":[{"name":"scheme","type":"string"},{"name":"remoteip","type":"string"},{"name":"query","type":"string"},{"name":"port","type":"int"},{"name":"path","type":"string"},{"name":"method","type":"string"},{"name":"host","type":"string"},{"name":"headers","type":{"type":"array","items":{"type":"array","items":"string"}}},{"name":"correlation","type":"string"}]}},{"name":"extensions","type":{"name":"extensions","type":"record","fields":[]}},{"name":"eventTypeVersion","type":"string"},{"name":"eventType","type":"string"},{"name":"eventTime","type":"string"},{"name":"eventID","type":"string"},{"name":"data","type":{"name":"data","type":"record","fields":[{"name":"foo","type":"string"}]}},{"name":"contentType","type":"string"},{"name":"cloudEventsVersion","type":"string"}]}'

# Consume
kafka-avro-console-consumer --topic rigAvro \
--bootstrap-server kafka:9292 \
--property schema.registry.url='http://kafka-schema-registry:8081'
```
