---
id: event-format
title: Event Format
sidebar_label: Event Format
---

[CloudEvents] is an upcoming [CNCF] standard for describing events in a consistent and portable way. We believe that CloudEvents brings benefits at a very low adoption cost. After all, any custom-developed event envelope-format likely contains the same properties anyway; CloudEvents mostly just make sure they are named the same way.

We aim at following the [CloudEvents specification](https://github.com/cloudevents/spec) as closely as possible. This includes the event format itself, but also the way events are serialized on different transport, the so-called _transport bindings_.

<details>
<summary>Example event</summary>
<p>

```json
{
  "specversion": "0.2",
  "type": "com.github.pull.create",
  "source": "https://github.com/cloudevents/spec/pull/123",
  "id": "A234-1234-1234",
  "time": "2018-04-05T17:31:00Z",
  "comexampleextension1": "value",
  "comexampleextension2": {
    "othervalue": 5
  },
  "contenttype": "text/xml",
  "data": "<much wow=\"xml\"/>"
}
```

</p>
</details>

## Encoding

In addition to JSON encoding, RIG also supports publishing CloudEvents using the [Apache Avro] format. With Confluent recommending the use of Avro in combination with their Kafka distribution, Avro sees much adoption lately, especially when used alongside the [Confluent Schema Registry](https://docs.confluent.io/current/schema-registry/index.html) ([open source](https://github.com/confluentinc/schema-registry) under the [Confluent Community License](https://www.confluent.io/confluent-community-license)). Consequently, RIG primarily supports the "registry model", where the message schema is not sent alongside every message; instead, [each message only contains a schema ID](https://docs.confluent.io/current/schema-registry/serializer-formatter.html#wire-format) and the schema itself is looked up (and cached) at runtime, using the Schema Registry.

To enable Avro & Schema Registry support, checkout the [Operator's Guide](rig-ops-guide) and look for the environment variable `KAFKA_SCHEMA_REGISTRY_HOST`.

For further details and examples, checkout the dedicated [Section on Avro](avro).

## Transport Bindings

When sending or receiving an event, you have a couple of options:

- Send the event as-is, or send only the "data" (= payload) in the "body" and the rest (the so-called "context attributes") in headers. The former is called _structured_ transport mode, while the latter is known as _binary_ transport mode.
- When using structured transport mode, the event may be encoded using JSON or Avro.
- Regardless of transport mode, the event's payload ("data" field or body) may be encoded in a format different from the event's encoding. For example, you might want to send CloudEvents in JSON format, but have their "data" field encoded using Protobuf.

Next we look at the HTTP and Kafka transport bindings in more detail.

## HTTP Transport Binding

RIG implements [HTTP Transport Binding for CloudEvents v0.2](https://github.com/cloudevents/spec/blob/v0.2/http-transport-binding.md), with the exception of _batched_ mode. The two supported modes of operation, _structured_ and _binary_, are described below.

### Structured

In structured mode the event is encoded in full and sent in the request body. The `content-type` HTTP header is expected to be `application/cloudevents+json` (`application/cloudevents+avro` might be supported in future versions of RIG).

While the specification defines that only the content type should be used to determine the transport mode, RIG also accepts messages with content type `application/json` as structured if, and only if, there is no `ce-specversion` HTTP header present in the request.

<details>
<summary>Example HTTP request with event in structured mode</summary>
<p>

HTTP header that announces a JSON-encoded CloudEvent:

```plaintext
Content-Type: application/cloudevents+json; charset=UTF-8
```

Request body:

```json
{
  "specversion": "0.2",
  "type": "com.example.someevent",
  "source": "example",
  "id": "80dc037c-fb24-43e9-9759-94f91f310a4b1",
  "data": {
    "this is": "the payload"
  }
}
```

</p>
</details>

### Binary

In binary mode the request body only contains the `data` value of the corresponding CloudEvent. The _context attributes_ - i.e., all other fields - are moved into the HTTP header (**this means also [extensions](https://github.com/cloudevents/spec/blob/v1.0/spec.md#extension-context-attributes)**). The data/body encoding is determined by the `content-type` header. At the time of writing there are two content types supported: `application/json` and `avro/binary`.

<details>
<summary>Same example event, sent using HTTP request in binary mode</summary>
<p>

In binary mode the HTTP header contains all context attributes. It also announces the body encoding:

```plaintext
ce-specversion: 0.2
ce-type: com.example.someevent
ce-source: example
ce-id: 80dc037c-fb24-43e9-9759-94f91f310a4b1
Content-Type: application/json; charset=UTF-8
```

Request body:

```json
{
  "this is": "the payload"
}
```

</p>
</details>

## Kafka Transport Binding

Implemented using [Kafka Transport Binding for CloudEvents v1.0](https://github.com/cloudevents/spec/blob/v1.0/kafka-protocol-binding.md). We utilize Kafka headers that have been introduced in Kafka version `0.11`. In order to support older Kafka versions as well, RIG defaults to structured mode and does not require any headers at all (see below).

Like with the HTTP transport binding, we define two modes of operation: structured and binary.

### Structured

In structured mode the event is encoded in full and sent as the message body. Structured mode is determined by parsing the `content-type` header, which defaults to `application/cloudevents+json`.

The default value means that the body contains a CloudEvents-formatted event in JSON encoding. The related content type for Avro encoding is `application/cloudevents+avro`.

<details>
<summary>Example event in structured mode</summary>
<p>

Message header that announces a JSON-encoded CloudEvent:

```plaintext
Content-Type: application/cloudevents+json; charset=UTF-8
```

Message body:

```json
{
  "specversion": "0.2",
  "type": "com.example.someevent",
  "source": "example",
  "id": "80dc037c-fb24-43e9-9759-94f91f310a4b1",
  "data": {
    "this is": "the payload"
  }
}
```

</p>
</details>

### Binary

In binary mode the message body only contains the `data` value of the corresponding CloudEvent. The _context attributes_ - i.e., all other fields - are moved into the message header (**this means also [extensions](https://github.com/cloudevents/spec/blob/v1.0/spec.md#extension-context-attributes)**). The data/body encoding is determined by the `content-type` header. In this mode there is no default for `content-type` and RIG rejects messages that come without it. At the time of writing there are two content types supported: `application/json` and `avro/binary`.

<details>
<summary>Same example in binary mode</summary>
<p>

In binary mode the message header contains all context attributes. It also announces the body encoding:

```plaintext
ce_specversion: 0.2
ce_type: com.example.someevent
ce_source: example
ce_id: 80dc037c-fb24-43e9-9759-94f91f310a4b1
Content-Type: application/json; charset=UTF-8
```

Message body:

```json
{
  "this is": "the payload"
}
```

</p>
</details>

[cloudevents]: https://cloudevents.io/
[cncf]: https://www.cncf.io/
[apache avro]: https://avro.apache.org/
