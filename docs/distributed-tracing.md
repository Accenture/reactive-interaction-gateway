---
id: distributed-tracing
title: Distributed Tracing
sidebar_label: Distributed Tracing
---

RIG is able to process distributed tracing data following the [W3C Trace Contexts](https://www.w3.org/TR/trace-context/). Sometimes RIG expects the trace context to be in the (HTTP) Header, and sometimes in the event payload itself. With events, we always speak of cloudevents following the [distributed tracing extension](https://github.com/cloudevents/spec/blob/v1.0/extensions/distributed-tracing.md).

There is one key rule when RIG expects the trace context either in the header or in the cloudevent:

1. if we talk of messages, then RIG expects the trace context to be in the (HTTP) header
2. if we talk of events (cloudevents), then RIG expects the trace context to be in the cloudevent

In our point of view, the difference of a message to an event is the following:

* a message is a request from one system to another for an action to be taken. The sender expects that the message will get processed somehow
* an event is a notification that data has been processed and some objects’ state has changed
* thus, a message and events have a different correlation between producer and consumer:
  * messages have 1-to-1 correlation between a producer and a consumer
  * events have a 1-to-n correlation between a producer and (potentially multiple) consumers

As a concrete example how distributed tracing has been implemented, read about it in the [channels-example](../examples/channels-example/README.md#one-word-to-distributed-tracing).
