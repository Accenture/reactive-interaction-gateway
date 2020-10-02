![Logo](./logo/Reactive-Interaction-Gateway-logo-cropped.png)

# RIG - Reactive Interaction Gateway

Makes frontend<->backend communication reactive based on events.

[![Build Status](https://travis-ci.org/Accenture/reactive-interaction-gateway.svg?branch=master)](https://travis-ci.org/Accenture/reactive-interaction-gateway)
[![DockerHub](https://img.shields.io/docker/pulls/accenture/reactive-interaction-gateway)](https://hub.docker.com/r/accenture/reactive-interaction-gateway)
[![Slack](https://rig-slackin.herokuapp.com/badge.svg)](https://rig-slackin.herokuapp.com)

Take a look at the [documentation](https://accenture.github.io/reactive-interaction-gateway/docs/intro.html) and get in touch with us on [Slack](https://rig-slackin.herokuapp.com)!

## About

The Reactive Interaction Gateway (RIG) is the glue between your client (frontend) apps and your backend. It makes communication between them easier by (click the links to learn more)

- [picking up backend events and forwarding them to clients based on subscriptions](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#picking-up-backend-events-and-forwarding-them-to-clients-based-on-subscriptions): this makes your frontend apps **reactive and eliminates the need for polling**.
- forwarding client requests to backend services **either synchronously, asynchronously or a mix of both**:
  - [synchronously](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#synchronously): if requests are being sent synchronously, RIG acts as a reverse proxy: RIG forwards the request to an HTTP endpoint of a backend service, waits for the response and sends it to the client.
  - [asynchronously - fire&forget](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#asynchronously---fireforget): RIG transforms a HTTP request to a message for asynchronous processing and forwards it to the backend asynchronously using either Kafka, NATS or Amazon Kinesis Data Streams.
  - [synchronously with asynchronous response](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#synchronously---asnychronous-response) - a pseudo-synchronous request: RIG forwards the client request to the backend synchronously via HTTP and waits for the backend response by listening to Kafka/NATS and forwarding it to the still open HTTP connection to the frontend.
  - [asynchronously with asynchronous response](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#asynchronously---asnychronous-response) - a pseudo-synchronous request: RIG forwards the client request to the backend asynchronously via Kafka or NATS and waits for the backend response by listening to Kafka/NATS and forwarding it to the still open HTTP connection to the frontend.

Built on open standards, RIG is very easy to integrate – and easy to replace – which means low-cost, low-risk adoption. Unlike other solutions, RIG does not leak into your application – no libraries or SDKs required. Along with handling client requests and publishing events from backend to the frontend, RIG provides [many built-in features](https://accenture.github.io/reactive-interaction-gateway/docs/features.html#built-in-features).

Learn more by taking a look into the [documentation](https://accenture.github.io/reactive-interaction-gateway/docs/intro.html) and the [FAQ](https://accenture.github.io/reactive-interaction-gateway/docs/faq.html).

## Getting Started

Take a look at the [getting-started tutorial](https://accenture.github.io/reactive-interaction-gateway/docs/tutorial.html).

### API Documentation

RIG exposes its API documentation on its API endpoint under [/swagger-ui](http://localhost:4010/swagger-ui). For integration into an existing swagger UI, the related JSON document can either be [retrieved at runtime](http://localhost:4010/swagger-ui/rig_api_swagger.json) or [found on disk](./priv/static/rig_api_swagger.json) after compiling RIG at least once.

### Metrics

RIG exposes Metrics in [Prometheus](https://prometheus.io/) format on its API endpoint under [/metrics](http:localhost:4010/metrics)

## Contribute

- **Use issues for everything.**
- For a small change, just send a PR.
- For bigger changes open an issue for discussion before sending a PR.
- PR should have:
  - Test case
  - Documentation (e.g., moduledoc, developer's guide, operator's guide)
  - Changelog entry
- You can also contribute by:
  - Reporting issues
  - Suggesting new features or enhancements
  - Improve/fix documentation

See the [developer's guide](https://accenture.github.io/reactive-interaction-gateway/docs/rig-dev-guide.html) and [CONTRIBUTING.md](./CONTRIBUTING.md) for details.

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
