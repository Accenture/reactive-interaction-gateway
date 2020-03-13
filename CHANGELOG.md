# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Support publishing events consumed from [NATS](https://nats.io) topics. See the [documentation](https://accenture.github.io/reactive-interaction-gateway/docs/event-streams.html#nats) for how to get started. [#297](https://github.com/Accenture/reactive-interaction-gateway/issues/297)
- Added validation for reverse proxy configuration. Now it crashes RIG on start when configuration is not valid or returns `400` when using REST API to update configuration. [#277](https://github.com/Accenture/reactive-interaction-gateway/issues/277)
- Added basic distributed tracing support in [W3C Trace Context specification](https://www.w3.org/TR/trace-context/) with Jaeger and Openzipkin exporters. RIG opens a span at the API Gateway and emits trace context in Cloud Events following the [distributed tracing spec](https://github.com/cloudevents/spec/blob/v1.0/extensions/distributed-tracing.md). [#281](https://github.com/Accenture/reactive-interaction-gateway/issues/281)
- Added possibility to set response code for `response_from` messages in reverse proxy (`kafka` and `http_async`). [#321](https://github.com/Accenture/reactive-interaction-gateway/pull/321)
- Added new version - `v3` - for internal endpoints to support response code in the `/responses` endpoint

### Changed

- Incorporated [cloudevents-ex](https://github.com/kevinbader/cloudevents-ex) to handle binary and structured modes for [Kafka protocol binding](https://github.com/cloudevents/spec/blob/v1.0/kafka-protocol-binding.md) in a proper way. This introduces some **breaking changes**:
  - Binary mode is now using `ce_` prefix for CloudEvents context attribute headers, before it was `ce-` - done according to the [Kafka protocol binding](https://github.com/cloudevents/spec/blob/v1.0/kafka-protocol-binding.md)
- Change above affects also `"response_from": "kafka"` proxy functionality. RIG will forward to clients only Kafka body, no headers. This means, when using binary mode, clients receive only the data part, no CloudEvents context attributes.
- Changed `response_from` handler to expect a message in binary format, **NOT** a cloud event (`kafka` and `http_async`). [#321](https://github.com/Accenture/reactive-interaction-gateway/pull/321)
- Updated Helm v2 template, kubectl yaml file and instructions in the `deployment` folder [#288](https://github.com/Accenture/reactive-interaction-gateway/issues/288)

### Fixed

- Fixed a bug where distributed set processes would crash when one of their peers has died but hasn't been removed yet from the pg2 group.

<!-- ### Deprecated -->

<!-- ### Removed -->

<!-- ### Security -->

<!-- ### Technical Improvements -->

## [2.4.0] - 2020-05-07

### Added

- Added possibility to define Kafka/Kinesis topic and schema per reverse proxy endpoint. The current solution using environment variables is deprecated, but still used as a fallback -- will be removed in the version 3.0.
  [#229](https://github.com/Accenture/reactive-interaction-gateway/issues/229)
- Added Kinesis + Localstack example.
  [#229](https://github.com/Accenture/reactive-interaction-gateway/issues/229)

### Technical Improvements

- Upgrade the Elixir version to 1.10 for source code and Docker images. Upgrade version for multiple dependencies.
  [#285](https://github.com/Accenture/reactive-interaction-gateway/issues/285)
- Added [Slackin](https://rig-slackin.herokuapp.com/) integration for easier Slack access - check the main page badge!
  [#240](https://github.com/Accenture/reactive-interaction-gateway/issues/240)

## [2.3.0] - 2019-12-13

### Added

- In addition to SSE and WebSocket, RIG now also supports HTTP long-polling for listening to events. Frontends should only use this as a fallback in situations where neither SSE nor WebSocket is supported by the network.
  [#217](https://github.com/Accenture/reactive-interaction-gateway/issues/217)
- When terminating an SSE connection after its associated session has been blacklisted, RIG now sends out a `rig.session_killed` event before closing the socket. For WebSocket connections, the closing frame contains "Session killed." as its payload.
  [#261](https://github.com/Accenture/reactive-interaction-gateway/pull/261)
- New API for querying and updating the session blacklist: `/v2/session-blacklist`, which introduces the following breaking changes (`/v1/session-blacklist` is unaffected) [#261](https://github.com/Accenture/reactive-interaction-gateway/pull/261):
  - When a session has been added to the session blacklist successfully, the endpoint now uses the correct HTTP status code "201 Created" instead of "200 Ok".
  - When using the API to blacklist a session, the `validityInSeconds` should now be passed as an integer value (using a string still works though).

### Fixed

- Fixed usage of external check for `SUBMISSION_CHECK` and `SUBSCRIPTION_CHECK`.
  [#241](https://github.com/Accenture/reactive-interaction-gateway/issues/241)
- Logging incoming HTTP request to Kafka works again and now also supports Apache Avro.
  [#170](https://github.com/Accenture/reactive-interaction-gateway/issues/170)
- Fixed HTTP response for `DELETE 4010/v1/apis/api_id` and `DELETE 4010/v2/apis/api_id` to correctly return `204` and no content.

### Removed

- Removed the `JWT_BLACKLIST_DEFAULT_EXPIRY_HOURS` environment variable ([deprecated since 2.0.0-beta.2](https://github.com/Accenture/reactive-interaction-gateway/commit/f974533455aa3ebc550ee95bf291585925a406d5)).
  [#260](https://github.com/Accenture/reactive-interaction-gateway/pull/260)

### Security

- A connection is now associated to its session right after the connection is established, given the request carries a JWT in its authorization header. Previously, this was only done by the subscriptions endpoint, which could cause a connection to remain active even after blacklisting its authorization token.
  [#260](https://github.com/Accenture/reactive-interaction-gateway/pull/260)

### Technical Improvements

- Upgrade the Elixir and Erlang versions for source code and Docker images.
  [#211](https://github.com/Accenture/reactive-interaction-gateway/issues/211)
- Automated UI-tests using Cypress make sure that all examples work and that code changes do not introduce any unintended API changes.
  [#227](https://github.com/Accenture/reactive-interaction-gateway/issues/227)
- Refactor JWT related code in favor of `RIG.JWT`.
  [#244](https://github.com/Accenture/reactive-interaction-gateway/pull/244)
- Fix flaky cypress tests; this shouldn't be an issue anymore when running Travis builds.
  [#265](https://github.com/Accenture/reactive-interaction-gateway/pull/265)

## [2.2.1] - 2019-06-21

### Changed

- Increased maximum number of Erlang ports from 4096 to 65536 to allow more HTTP connections.

## [2.2.0] - 2019-06-17

### Added

- New Prometheus metric: `rig_proxy_requests_total`. For details see [`metrics-details.md`](docs/metrics-details.md).
  [#157](https://github.com/Accenture/reactive-interaction-gateway/issues/157)
- The respond-via-Kafka feature uses a correlation ID for associating the response with the original request. This correlation ID is now cryptographically verified, which prevents an attacker on the internal network to reroute responses to other users connected to RIG.
  [#218](https://github.com/Accenture/reactive-interaction-gateway/pull/218)
- Apache Avro is now supported for consuming from, and producing to, Kafka. The implementation uses the Confluent Schema Registry to fetch Avro schemas.
- Added new set of topics in documentation about the API Gateway, even streams and scaling.
- Added examples section to the documentation website.
- Added new `response_from` option -- `http_async` together with new internal `POST` endpoint `/v1/responses`. You can send correlated response to `/v1/responses` and complete initial Proxy request.
  [#213](https://github.com/Accenture/reactive-interaction-gateway/issues/213)
- Implement [HTTP Transport Binding for CloudEvents v0.2](https://github.com/cloudevents/spec/blob/v0.2/http-transport-binding.md). A special fallback to "structured mode" in case the content type is "application/json" and the "ce-specversion" header is not set ensures this change is backward compatible with existing setups.
  [#153](https://github.com/Accenture/reactive-interaction-gateway/issues/153)
- New request body format for endpoints with `kafka` and `kinesis` targets; see [Deprecated](#Deprecated) below.

### Changed

- The environment variable `KAFKA_GROUP_ID` has been replaced with the following environment variables, where each of them has a distinct default value: `KAFKATOFILTER_KAFKA_GROUP_ID`, `KAFKATOHTTP_KAFKA_GROUP_ID`, `PROXY_KAFKA_RESPONSE_KAFKA_GROUP_ID`.
  [#206](https://github.com/Accenture/reactive-interaction-gateway/issues/206)
- The default Kafka source topic for the Kafka-to-HTTP event stream has been changed to `rig`. The feature was introduced to forward all incoming events to an (external) HTTP endpoint, so it makes sense to use the default topic for incoming events here too.
- Changed `:refresh_subscriptions` GenServer handler from `call` to `cast` to improve performance.
  [#224](https://github.com/Accenture/reactive-interaction-gateway/pull/224/files)

### Fixed

- Fixed a bug that caused the subscriptions endpoint to return an internal server error when running RIG in a clustered setup.
  [#194](https://github.com/Accenture/reactive-interaction-gateway/issues/194)
- Support for forwarding HTTP/1.1 responses over a HTTP/2 connection by dropping connection-related HTTP headers.
  [#193](https://github.com/Accenture/reactive-interaction-gateway/issues/193)
- Added missing `id` field to swagger spec for `message` API.
- Fixed random generation of group IDs for Kafka consumer groups. This led to wrong partition distribution when using multiple RIG nodes. Now consumers will have the same ID which can be changed via environment variable - defaults to `rig`.
- When forwarding an HTTP request, the [`Host`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host) request header is now set to the `target_url` defined by the proxy configuration.
  [#188](https://github.com/Accenture/reactive-interaction-gateway/issues/188)
- Fixed missing `swagger.json` file in production Docker image.
- Added missing CORS headers for Kafka/Kinesis target type when not using `response_from`.
- Fixed schema registry validation when using binary messages in Kafka consumer.
  [#202](https://github.com/Accenture/reactive-interaction-gateway/issues/202)
- Forwarding events to HTTP did not contain (all) Kafka messages, as the Kafka consumer group ID was shared with the consumer for forwarding events to frontends.
  [#206](https://github.com/Accenture/reactive-interaction-gateway/pull/206)

### Deprecated

- Endpoints configured with target `kafka` or `kinesis` now expect a different body format (that is, the previous format is deprecated). This aligns the request body format with the other endpoints that accept CloudEvents.

  For example, instead of using this:

  ```json
  {
    "partition": "the-partition-key",
    "event": {
      "specversion": "0.2",
      "type": "what_has_happened",
      "source": "ui",
      "id": "123"
    }
  }
  ```

  you should put the partition key in the CloudEvent's "rig" extension instead:

  ```json
  {
    "specversion": "0.2",
    "rig": {
      "target_partition": "the-partition-key"
    },
    "type": "what_has_happened",
    "source": "ui",
    "id": "123"
  }
  ```

## [2.1.1] - 2019-03-27

### Added

- When using the proxy, RIG will now add an additional [`Forwarded` header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Forwarded).
  [#113](https://github.com/Accenture/reactive-interaction-gateway/issues/113)
- Increased length of header value in HTTP requests to 16384 to support long tokens for SAML.

### Changed

- HTTPS certificates may now be passed using absolute paths. (Previously, the locations of the HTTPS certificates were limited to the OTP-applications' `priv` directories `rig_api/priv/cert` and `rig_inbound_gateway/priv/cert`.) Additionally, for security reasons we no longer include the self-signed certificate with the docker image. Please adapt your environment configuration accordingly.
  [#151](https://github.com/Accenture/reactive-interaction-gateway/issues/151)
  [#182](https://github.com/Accenture/reactive-interaction-gateway/issues/182)
- Validation errors for SSE & WS connections and the subscriptions endpoint should now be a lot more helpful. Invalid JWTs, as well as invalid subscriptions, cause the endpoints to respond with an error immediately.
  [#54](https://github.com/Accenture/reactive-interaction-gateway/issues/54)
  [#164](https://github.com/Accenture/reactive-interaction-gateway/issues/164)

### Fixed

- Parsing of JSON files in proxy module - `api.id` was expected to be an atom, but when using files it's a string.
- Kinesis: Support for CloudEvents versions 0.1 and 0.2.
- Fixed channels example with latest RIG API changes.
- Fixed sse/ws examples to use JWT inferred subscriptions correctly.

## [2.1.0] - 2019-02-15

### Added

- Prometheus monitoring endpoint.
  [#96](https://github.com/Accenture/reactive-interaction-gateway/issues/96)
- The proxy configuration can now also be passed as a JSON string. This allows to run the Docker image in environments where mounting a file in a container is not possible.
  [#159](https://github.com/Accenture/reactive-interaction-gateway/issues/159)

### Removed

- Rate limiting.
  [#144](https://github.com/Accenture/reactive-interaction-gateway/issues/144)

## [2.0.2] - 2019-01-20

### Fixed

- Upgraded a dependency to fix the Docker build.
  [#149](https://github.com/Accenture/reactive-interaction-gateway/issues/149)

## [2.0.1] - 2019-01-20

### Fixed

- A library upgrade caused idle SSE connections to time out after 60 seconds. This timeout is now disabled.
  [#148](https://github.com/Accenture/reactive-interaction-gateway/pull/148)

## [2.0.0] - 2019-01-16

### Added

- HTTP/2 and HTTPS support.
  [#34](https://github.com/Accenture/reactive-interaction-gateway/issues/34)
- The SSE and WebSocket endpoints now take a "subscriptions" parameter that allows to create (manual) subscriptions (JSON encoded list). This has the same effect as establishing a connection and calling the subscriptions endpoint afterwards.
- OpenAPI (Swagger) documentation for RIG's internal API.
  [#116](https://github.com/Accenture/reactive-interaction-gateway/issues/116)
- Support for the CloudEvents v0.2 format.
  [#112](https://github.com/Accenture/reactive-interaction-gateway/issues/112)
- In API definitions regular expressions can now be used to define matching request paths. Also, request paths can be rewritten (see [api.ex](apps/rig_inbound_gateway/lib/rig_inbound_gateway/api_proxy/api.ex) for an example).
  [#88](https://github.com/Accenture/reactive-interaction-gateway/issues/88)

### Changed

- The SSE and WebSocket endpoints' "token" parameter is renamed to "jwt" (to not confuse it with the connection token).
- When forwarding requests, RIG related meta data (e.g. correlation ID) in CloudEvents is now put into an object under the top-level key "rig". Note that in terms of the current [CloudEvents 0.2](https://github.com/cloudevents/spec/blob/v0.2/spec.md) specification this makes "rig" an [extension](https://github.com/cloudevents/spec/blob/v0.2/primer.md#cloudevent-attribute-extensions). Also, all RIG related keys have been renamed from snake_case to camelCase.
- Previously API definitions for proxy were turning on security check for endpoints by `not_secured: false` which is a bit confusing -- changed to more readable form `secured: true`.
- No longer assumes the "Bearer" token type when no access token type is prepended in the Authorization header. Consequently, a client is expected to explicitly use "Bearer" for sending its JWT authorization token. More more details, see [RFC 6749](https://tools.ietf.org/html/rfc6749#section-7.1).
- All events that RIG creates are now in CloudEvents v0.2 format (before: CloudEvents v0.1).
- When using Kafka or Kinesis as the target, connection related data is added to the event before publishing it to the respective topic/partition. With the introduction of CloudEvents v0.2, RIG now follows the CloudEvent extension syntax with all fields put into a common top-level object called "rig". Additionally, the object's field names have been changed slightly to prevent simple mistakes like case-sensitivity issues. Also, the expected request body fields have been renamed to be more descriptive. To that end, usage information returned as plaintext should help the API user in case of a Bad Request.

### Fixed

- Extractor configuration reload
- Fixed response to CORS related preflight request.

## [2.0.0-beta.2] - 2018-11-09

### Added

- JWT now supports RS256 algorithm in addition to HS256.
  [#84](https://github.com/Accenture/reactive-interaction-gateway/issues/84)
- Support Kafka SSL and SASL/Plain authentication.
  [#79](https://github.com/Accenture/reactive-interaction-gateway/issues/79)
- Add new endpoints at `/_rig/v1/` for subscribing to CloudEvents using SSE/WS, for creating subscriptions to specific event types, and for publishing CloudEvents.
  [#90](https://github.com/Accenture/reactive-interaction-gateway/issues/90)
- Expose setting for proxy response timeout.
  [#91](https://github.com/Accenture/reactive-interaction-gateway/issues/91)
- Subscriptions inference using JWT on SSE/WS connection and subscription creation.
  [#90](https://github.com/Accenture/reactive-interaction-gateway/issues/90)
- Allow publishing events to Kafka and Kinesis via reverse-proxy HTTP calls. Optionally, a response can be waited for (using a correlation ID).
- Simple event subscription examples for SSE and WS.
- Kafka/Kinesis firehose - set topic/stream to consume and invoke HTTP request when event is consumed.

### Changed

- SSE heartbeats are now sent as comments rather than events, and events without data carry an empty data line to improve cross-browser compatibility.
  [#64](https://github.com/Accenture/reactive-interaction-gateway/issues/64)
- General documentation and outdated info.

### Removed

- Previous SSE/WS communication via Phoenix channels.
- Events that don't follow the CloudEvents spec are no longer supported (easy migration: put your event in a CloudEvent's `data` field).

### Fixed

- Flaky tests in `router_test.exs` -- switching from `Bypass` to `Fakeserver`.
  [#74](https://github.com/Accenture/reactive-interaction-gateway/issues/74)
- Channels example. [#64](https://github.com/Accenture/reactive-interaction-gateway/issues/64)

## [2.0.0-beta.1] - 2018-06-21

### Added

- Amazon Kinesis integration.
  [#27](https://github.com/Accenture/reactive-interaction-gateway/issues/27)
- Use lazy logger calls for debug logs.
- Format (most files) using Elixir 1.6 formatter.
- Add new endpoint `POST /messages` for sending messages (=> Kafka is no longer a hard dependency).
- Add a dedicated developer guide.
- Release configuration in `rel/config.exs` and custom `vm.args` (based on what distillery is using).
  [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
- Production configuration for peerage to use DNS discovery.
  [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
- Module for auto-discovery, using `Peerage` library.
  [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
- Kubernetes deployment configuration file.
  [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
- Smoke tests setup and test cases for API Proxy and Kafka + Phoenix messaging.
  [#42](https://github.com/Accenture/reactive-interaction-gateway/pull/42)
- Kafka consumer ready check utility function.
  [#42](https://github.com/Accenture/reactive-interaction-gateway/pull/42)
- List of all environment variables possible to set in `guides/operator-guide.md`.
  [#36](https://github.com/Accenture/reactive-interaction-gateway/pull/36)
- Possibility to set logging level with env var `LOG_LEVEL`.
  [#49](https://github.com/Accenture/reactive-interaction-gateway/pull/49)
- Variations of Dockerfiles - basic version and AWS version.
  [#44](https://github.com/Accenture/reactive-interaction-gateway/pull/44)
- Helm deployment chart.
  [#59](https://github.com/Accenture/reactive-interaction-gateway/pull/59)
- Proxy is now able to do request header transformations.
  [#76](https://github.com/Accenture/reactive-interaction-gateway/pull/76)

### Changed

- Endpoint for terminating a session no longer contains user id in path.
- Convert to umbrella project layout.
- Move documentation from `doc/` to `guides/` as the former is the default for ex_doc output.
- Revised request logging (currently Kafka and console as backends).
- Disable WebSocket timeout.
  [#58](https://github.com/Accenture/reactive-interaction-gateway/pull/58)
- Dockerfile to use custom `vm.args` file & removed `mix release.init` step.
  [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)

### Fixed

- Make presence channel respect `JWT_USER_FIELD` setting (currently hardcoded to "username").
- Set proper environment variable for Phoenix server `INBOUND_PORT`.
  [#38](https://github.com/Accenture/reactive-interaction-gateway/pull/38)
- Set proper environment variable for Phoenix server `API_PORT`.
  [#38](https://github.com/Accenture/reactive-interaction-gateway/pull/38)
- Channels example fixed to be compatible with version 2.0.0.
  [#40](https://github.com/Accenture/reactive-interaction-gateway/pull/40)
- User defined query auth values are no longer overridden by `JWT` auth type.
- Handle content-type correctly.
  [#61](https://github.com/Accenture/reactive-interaction-gateway/pull/61)
- More strict regex match for routes in proxy.
  [#76](https://github.com/Accenture/reactive-interaction-gateway/pull/76)
- Downcased response headers to avoid duplicates in proxy.
  [#76](https://github.com/Accenture/reactive-interaction-gateway/pull/76)

## [1.1.0] - 2018-01-11

### Added

- Basic Travis configuration.
  [#17](https://github.com/Accenture/reactive-interaction-gateway/pull/17)
- Configuration ADR document.
  [#19](https://github.com/Accenture/reactive-interaction-gateway/pull/19)
- Websocket and SSE channels example.
  [#22](https://github.com/Accenture/reactive-interaction-gateway/pull/22)
- Maintain changelog file.
  [#25](https://github.com/Accenture/reactive-interaction-gateway/pull/25)

### Changed

- Increase default rate limits.
  [#16](https://github.com/Accenture/reactive-interaction-gateway/pull/16)
- Make producing of Kafka messages in proxy optional (and turned off by default).
  [#21](https://github.com/Accenture/reactive-interaction-gateway/pull/21)

### Fixed

- Fix Travis by disabling credo rule `Design.AliasUsage`.
  [#18](https://github.com/Accenture/reactive-interaction-gateway/pull/18)

## 1.0.0 - 2017-11-09

### Added

- Add `mix docs` script to generate documentation of code base.
  [#6](https://github.com/Accenture/reactive-interaction-gateway/pull/6)
- Add ethics documentation such as code of conduct and contribution guidelines.
  [#6](https://github.com/Accenture/reactive-interaction-gateway/pull/6)

### Changed

- Update configuration to be able to modify almost anything by environment variables on RIG start.
  [#5](https://github.com/Accenture/reactive-interaction-gateway/pull/5)
- Rework Dockerfile to use multistage approach for building RIG Docker image.
  [#9](https://github.com/Accenture/reactive-interaction-gateway/pull/9)
- Update entire code base to use `rig` keyword.
  [#13](https://github.com/Accenture/reactive-interaction-gateway/pull/13)

### Removed

- Disable Origin checking.
  [#12](https://github.com/Accenture/reactive-interaction-gateway/pull/12)

[unreleased]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.4.0...HEAD
[2.4.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.2.1...2.3.0
[2.2.1]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.2.0...2.2.1
[2.2.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.1.1...2.2.0
[2.1.1]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.2...2.1.0
[2.0.2]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.0-beta.2...2.0.0
[2.0.0-beta.2]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.0-beta.1...2.0.0-beta.2
[2.0.0-beta.1]: https://github.com/Accenture/reactive-interaction-gateway/compare/1.1.0...2.0.0-beta.1
[1.1.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/1.0.0...1.1.0
