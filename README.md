![Logo](./logo/Reactive-Interaction-Gateway-logo-cropped.png)

# RIG - Reactive Interaction Gateway

Makes frontend<->backend communication reactive and event-driven.

[![Build Status](https://travis-ci.org/Accenture/reactive-interaction-gateway.svg?branch=master)](https://travis-ci.org/Accenture/reactive-interaction-gateway)
[![DockerHub](https://img.shields.io/docker/pulls/accenture/reactive-interaction-gateway)](https://hub.docker.com/r/accenture/reactive-interaction-gateway)

## About

The Reactive Interaction Gateway (RIG) is the glue between your client (frontend) and your backend. It makes communication between them easier by (click the links to learn more)

- picking up backend events and forwarding them to clients based on subscriptions: this makes your frontend apps **reactive and eliminates the need for polling**. You can do this
  - [asynchronously](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#picking-up-backend-events-and-forwarding-them-to-clients-based-on-subscriptions#asynchronously) - using Kafka, Nats or Kinesis.
  - [synchronously](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#picking-up-backend-events-and-forwarding-them-to-clients-based-on-subscriptions#synchronously) - if you don't want to manage a (potentially complex) message broker system like Kafka.
- forwarding client requests to backend services either synchronously, asynchronously or a mix of both:
  - [synchronously](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#synchronously) - if requests are being sent synchronously, RIG acts as a reverse proxy: RIG forwards the request to an HTTP endpoint of a backend service, waits for the response and sends it to the client.
  - [asynchronously - fire&forget](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#asynchronously---fireforget) - RIG transforms a HTTP request to a message for asynchronous processing and forwards it to the backend asynchronously using either Kafka, NATS or Amazon Kinesis.
  - [synchronously with asynchronous response](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#synchronously---asnychronous-response) - a pseudo-synchronous request: RIG forwards the client request to the backend synchronously via HTTP and waits for the backend response by listening to Kafka/NATS and forwarding it to the still open HTTP connection to the frontend.
  - [asynchronously with asynchronous response](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#asynchronously---asnychronous-response) - a pseudo-synchronous request: RIG forwards the client request to the backend asynchronously via Kafka or NATS and waits for the backend response by listening to Kafka/NATS and forwarding it to the still open HTTP connection to the frontend.

Built on open standards, RIG is very easy to integrate – and easy to replace – which means low-cost, low-risk adoption. Unlike other solutions, RIG does not leak into your application – no libraries or SDKs required. Along with handling client requests and publishing events from backend to the frontend, RIG provides [many out-of-the-box features](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#out-of-the-box-features).

This is just a basic summary of what RIG can do. There is a comprehensive documentation available on our [website](https://accenture.github.io/reactive-interaction-gateway/docs/intro.html). If you have any unanswered question, check out the [FAQ](https://accenture.github.io/reactive-interaction-gateway/docs/faq.html) section to get them answered.

## Getting Started

- Take a look at the [getting-started tutorial](https://accenture.github.io/reactive-interaction-gateway/docs/tutorial.html) for a simple walkthrough using docker
- For deploying RIG on Kubernetes, check out the [Kubernetes deployment instructions](https://github.com/Accenture/reactive-interaction-gateway/tree/284-document-sync-async-http-to-kafka/deployment)

## Get Involved

- [Ask anything by opening GitHub issues](https://github.com/Accenture/reactive-interaction-gateway/issues/new/choose)
- Follow us on [Twitter](https://twitter.com/reactivegateway)
- Start contributing: refer to our [contributing guide](./CONTRIBUTING.md)
- Develop RIG: refer to our [developer's guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-dev-guide.html)

## License

The Reactive Interaction Gateway [(patent: granted)](https://patents.google.com/patent/US10193992B2/en) is licensed under the Apache License 2.0 - see
[LICENSE](LICENSE) for details.

## Acknowledgments

The Reactive Interaction Gateway is sponsored and maintained by [Accenture](https://accenture.github.io/).

Kudos to these awesome projects:

- Elixir
- Erlang/OTP
- Phoenix Framework
- Brod
- Distillery
