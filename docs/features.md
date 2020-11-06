---
id: features
title: Features
sidebar_label: Features
---

* [Picking up backend events and forwarding them to clients based on subscriptions](#picking-up-backend-events-and-forwarding-them-to-clients-based-on-subscriptions)
* [Forwarding client requests to backend services](#forwarding-client-requests-to-backend-services)
  * [Synchronously](#synchronously)
  * [Asynchronously - Fire&Forget](#asynchronously---fireforget)
  * [Synchronously - Asnychronous Response](#synchronously---asnychronous-response)
  * [Asynchronously - Asnychronous Response](#asynchronously---asnychronous-response)
* [Out-of-the-box Features](#out-of-the-box-features)

RIG can be used in different scenarios.

## Picking up backend events and forwarding them to clients based on subscriptions

RIG acts as a fan-out publisher of backend events. Clients can simply subscribe to RIG in order to receive these events. This makes your frontend apps reactive and eliminates the need for polling.

Additionally clients can provide filters during the subscription initialization and tell RIG in what type of events it is interested in. Those filters allow clients to tap into high-volume event streams without getting overwhelmed by unwanted events. In other words, filters enable bandwidth efficiency.

[The concert example use case](https://accenture.github.io/reactive-interaction-gateway/docs/intro.html#use-case-real-time-updates) describes one advantage of this reactive architectural approach. Check out the [Intro](https://accenture.github.io/reactive-interaction-gateway/docs/intro.html#reactive-interaction-gateway) for a detailed description and architecture diagram. Basically it works like this:

![fan-out-to-multiple-clients](./assets/features-fan-out-to-multiple-clients.png)

## Forwarding client requests to backend services

When client requests need to be forwarded to the backend, clients sometimes are interested in the response of the backend, and sometimes not. Especially when the client is interested in the direct response of the backend, there are a couple of options how to design that technically.

### Synchronously

If requests are being sent synchronously, RIG acts as a reverse proxy: RIG forwards the request to an HTTP endpoint of a backend service, waits for the response and sends it back to the client. It is as simple as

![client-to-backend-synchronously](./assets/features-client-to-backend-synchronously.png)

You may ask: Why shouldn't I directly talk to the backend? What benefits does RIG provide?

RIG provides many additional features on top like session management or JWT signature verification. You don't have to implement this over and over again at the clients and backend services. That said, it's perfectly fine to run RIG alongside an existing API management gateway, too.

### Asynchronously - Fire&Forget

RIG transforms a HTTP request to a message for asynchronous processing and forwards it to the backend asynchronously using either [Kafka](https://kafka.apache.org/), [NATS](https://nats.io/) or [Amazon Kinesis](https://aws.amazon.com/kinesis/).

![client-to-backend-asynchronously-fireandforget](./assets/features-client-to-backend-asynchronously-fireandforget.png)

This enables asynchonous communication between client-side applications and the backend. RIG acts as a bridge between its clients and the messaging system. Similar to above, the authenticity of client requests are validated using JWT signature verification. RIG effectively replaces a custom backend application that would accept client requests and forward them to Kafka, Nats or Kinesis. This additional backend app is a single point of failure, hence it would be necessary to harden it and make it highly available and reliable. With RIG, you don't have to take care of that - RIG is [scalable by design](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#out-of-the-box-features).

### Synchronously - Asnychronous Response

RIG forwards the client request to the backend synchronously via HTTP and waits for the backend response by listening to Kafka/NATS and forwarding it to the still open HTTP connection to the frontend.

![client-to-backend-synchronously-asynchronous-response](./assets/features-client-to-backend-synchronously-asynchronous-response.png)

This scenario can be quite useful which is described in more detail in the [Architecture section](https://accenture.github.io/reactive-interaction-gateway/docs/architecture.html#providing-a-synchronous-api-for-asynchronous-back-end-services). RIG correlates the corresponding answer using the correlation ID of the oRIGinal request, that will be forwarded to the backend and also being used in the response of the backend. With this ID, RIG can filter the appropriate message from the consuming topic.

As you can see in the architecture diagram, the backend service responds to RIG with `202 Accepted` to tell RIG that the response will be provided asynchronously.

Apart from that, the backend service also has the possibility to return a cached response (this will be a `200 OK` response with a corresponding http body) or anything else, e.g. a `400 Bad Request`. In turn, RIG will not listen to the topic and wait for the response. Consequently, the request flow will look similar to the [synchronous approach](#synchronously).

### Asynchronously - Asnychronous Response

RIG forwards the client request to the backend asynchronously via Kafka or NATS and waits for the backend response by listening to Kafka/NATS and forwarding it to the still open HTTP connection to the frontend.

![client-to-backend-asynchronously-asynchronous-response](./assets/features-client-to-backend-asynchronously-asynchronous-response.png)

Essentially this is a combination of the [asynchronous - fire&forget approach](#asynchronously---fireforget) and the [synchronous - asynchronous response approach](#synchronously---asnychronous-response).

## Out-of-the-box Features  

Built on open standards, RIG is very easy to integrate – and easy to replace – which means low-cost, low-risk adoption. Unlike other solutions, RIG does not leak into your application – no libraries or SDKs required. Along with handling client requests and publishing events from backend to the frontend, RIG provides many out-of-the-box features:

- Easy to use and scalable by design:
  - Supports tens of thousands stable connections per node even on low-end machines
  - Easy to add additional nodes
  - Built on the battle-proven [Erlang/OTP](http://www.erlang.org/) distribution model
  - Only uses in-memory data structures - no external dependencies to configure or scale
- Connect using standard protocols:
  - Firewall friendly and future proof using Server-Sent Events (SSE)
    - [HTML5 standard](https://html.spec.whatwg.org/multipage/server-sent-events.html#server-sent-events)
    - Regular HTTP requests, so no issues with proxy servers or firewalls
    - Connection multiplexing with HTTP/2 out of the box
    - SSE implementation (browser) keeps track of connection drops and restores the connection automatically
    - Polyfills available for older browsers
  - WebSocket connections are supported, too
  - HTTP long polling for situations where SSE and WS are not supported
- Publish events from various sources:
  - Kafka
  - NATS
  - Amazon Kinesis
  - or publish via HTTP
- Convert a HTTP request to a message for asynchronous processing:
  - produce to Kafka topic, optionally wait for the result on another Kafka topic
  - produce to a NATS topic, optionally using NATS request-response to wait for the result
  - produce to Amazon Kinesis
- Uses the CNCF [CloudEvents specification](https://cloudevents.io/)
- Takes care of client connection state so you don't have to
- Flexible event subscription model based on event types
- Use existing services for authentication and authorization of users and subscriptions
- JWT signature verification for APIs as a simple authentication check
- Session blacklist with immediate session invalidation
