---
id: distributed-tracing
title: Distributed Tracing
sidebar_label: Distributed Tracing
---

RIG is able to process distributed tracing data following the [W3C Trace Contexts](https://www.w3.org/TR/trace-context/). Sometimes RIG expects the trace context in a (HTTP) Header, and sometimes in the event payload itself. With events, we always speak of cloudevents following the [distributed tracing extensions](https://github.com/cloudevents/spec/blob/v1.0/extensions/distributed-tracing.md).

There is one key rule when RIG expects the trace context either in the header or in the cloudevent:

1. if we talk of messages, then RIG expects the trace context to be in the (HTTP) header
2. if we talk of events (cloudevents), then RIG expects the trace context to be in the cloudevent

In our point of view, the difference of a message to an event is the following:

* Every event is a message
* but not every message is an event
* a message is only an event, if there is a 1 to any correlation between a producer and (potentially multiple) consumers

As a concrete example, read about it in the [channels-example](../examples/channels-example/README.md#one-word-to-distributed-tracing).
