---
id: event-serializing
title: Event Serializing
sidebar_label: Event Serializing
---

TODO

## Structured mode

topic, key, headers - content type, value - data and cloud event thingies

## Binary mode

topic, key, headers - cloud events thingies, value - data

## Avro

### Format

magic byte, schema id, data

### Implementation

### Producer example

### Consumer example

```bash
{"schema":"{\"name\":\"myrecord\",\"type\":\"record\",\"fields\":[{\"name\":\"foo\",\"type\":\"string\"}]}"}
```

```bash
KAFKA_BROKERS=localhost:9092 \
KAFKA_SERIALIZER=avro \
KAFKA_SOURCE_TOPICS=test2 \
PROXY_CONFIG_FILE=proxy/proxy.testx.json \
PROXY_KAFKA_REQUEST_TOPIC=test2 \
PROXY_KAFKA_REQUEST_AVRO=test2-value \
mix phx.server
```

```bash
{"schema":"{\"name\":\"myrecord\",\"type\":\"record\",\"fields\":[{\"name\":\"source\",\"type\":\"string\"},{\"name\":\"rig\",\"type\":{\"name\":\"rig\",\"type\":\"record\",\"fields\":[{\"name\":\"scheme\",\"type\":\"string\"},{\"name\":\"remoteip\",\"type\":\"string\"},{\"name\":\"query\",\"type\":\"string\"},{\"name\":\"port\",\"type\":\"int\"},{\"name\":\"path\",\"type\":\"string\"},{\"name\":\"method\",\"type\":\"string\"},{\"name\":\"host\",\"type\":\"string\"},{\"name\":\"headers\",\"type\":{\"type\":\"array\",\"items\":{\"type\":\"array\",\"items\":\"string\"}}},{\"name\":\"correlation\",\"type\":\"string\"}]}},{\"name\":\"extensions\",\"type\":{\"name\":\"extensions\",\"type\":\"record\",\"fields\":[]}},{\"name\":\"eventTypeVersion\",\"type\":\"string\"},{\"name\":\"eventType\",\"type\":\"string\"},{\"name\":\"eventTime\",\"type\":\"int\",\"logicalType\":\"date\"},{\"name\":\"eventID\",\"type\":\"string\"},{\"name\":\"data\",\"type\":{\"name\":\"data\",\"type\":\"record\",\"fields\":[{\"name\":\"foo\",\"type\":\"string\"}]}},{\"name\":\"contentType\",\"type\":\"string\"},{\"name\":\"cloudEventsVersion\",\"type\":\"string\"}]}"}

kafka-avro-console-producer \
--broker-list rig-kafka:9092 --topic test2 \
--property schema.registry.url='http://rig-kafka-schema-registry:8081' \
--property value.schema='{"name":"myrecord","type":"record","fields":[{"name":"source","type":"string"},{"name":"rig","type":{"name":"rig","type":"record","fields":[{"name":"scheme","type":"string"},{"name":"remoteip","type":"string"},{"name":"query","type":"string"},{"name":"port","type":"int"},{"name":"path","type":"string"},{"name":"method","type":"string"},{"name":"host","type":"string"},{"name":"headers","type":{"type":"array","items":{"type":"array","items":"string"}}},{"name":"correlation","type":"string"}]}},{"name":"extensions","type":{"name":"extensions","type":"record","fields":[]}},{"name":"eventTypeVersion","type":"string"},{"name":"eventType","type":"string"},{"name":"eventTime","type":"string"},{"name":"eventID","type":"string"},{"name":"data","type":{"name":"data","type":"record","fields":[{"name":"foo","type":"string"}]}},{"name":"contentType","type":"string"},{"name":"cloudEventsVersion","type":"string"}]}'

{"source":"/postman","rig":{"scheme":"http","remoteip":"127.0.0.1","query":"","port":4000,"path":"/myapi/publish-async","method":"POST","host":"localhost","headers":[["accept","*/*"],["accept-encoding","gzip, deflate"],["cache-control","no-cache"],["connection","keep-alive"],["content-length","418"],["content-type","application/json"],["host","localhost:4000"],["postman-token","8e6cbed9-2d7d-4998-b90f-56a5fdeeb410"],["user-agent","PostmanRuntime/7.6.0"]],"correlation":"g2dkAA1ub25vZGVAbm9ob3N0AAAD7QAAAAAA"},"extensions":{},"eventTypeVersion":"1.0","eventType":"com.example","eventTime":"2018-04-05T17:31:00Z","eventID":"069711bf-3946-4661-984f-c667657b8d85","data":{"foo":"test"},"contentType":"application/json","cloudEventsVersion":"0.1"}

kafka-avro-console-consumer --topic rigAvro \
--bootstrap-server kafka:9292 \
--property schema.registry.url='http://kafka-schema-registry:8081'
```

```
kafka-console-producer \
--broker-list rig-kafka:9092 --topic test2
```

0.1
required fields: eventType, cloudEventsVersion, source, eventID
optional fields: eventTypeVersion, eventTime, schemaURL, contentType, extensions, data, rigextension

0.2
required fields: type, specversion, source, id
optional fields: time, schemaurl, contenttype, data, rigextension
