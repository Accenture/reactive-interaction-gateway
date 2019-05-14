---
id: examples
title: Examples
sidebar_label: Examples
---

We provide set of examples that should give you an idea on how to integrate RIG into your current application.

In the [`examples`] directory you can find several examples for both Server-Sent Events (SSE) and WebSocket (WS) based connections. The examples show how to use them in a simple way, but also in conjunction with JWT, constraints and extractors. They are designed to be executable with RIG as their only dependency.

Available examples:

- **API Gateway:** This is a playground where you can test various use cases mentioned in the [API Gateway](./api-gateway.md) Section.
- **Channels:** A slightly bigger example that uses Kafka, a small NodeJS microservice and a React based UI that lets you choose between an SSE and a WebSocket connection. The Channels example lets you see the entire communication flow from client, through RIG, to the microservice, to Kafka, to RIG again and finally back to the client. It's also lets you play around with public as well as with private subscriptions.
- **Avro:** Find an example around Avro in the [advanced guide](avro) dedicated to the topic.

[`examples`]: https://github.com/Accenture/reactive-interaction-gateway/tree/master/examples
