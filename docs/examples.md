---
id: examples
title: Examples
sidebar_label: Examples
---

To be able to quickly test and interact with RIG, we provide set of [examples](https://github.com/Accenture/reactive-interaction-gateway/tree/master/examples).

In root directory you can find several examples for Server-Sent Events (SSE) and Websockets (WS). Both versions are showcasing how to use them in a simplest way, but also in conjunction with JWT, constraints and extractors. These examples are very simple and don't require anything else, but RIG.

## API Gateway

This is tiny playground where you can test various use cases from [API Gateway](./api-gateway.md) section.

## Channels

Channels is slightly bigger example using Kafka, small NodeJS microservice and React UI (using both SSE and WS). Here you can see entire communication flow from client, through RIG, to microservice, to Kafka, to RIG and back to client. It's possible to try out public as well as private subscriptions.

## Avro

Avro example is located in [Event Serialization](./event-serialization.md#example) section.
