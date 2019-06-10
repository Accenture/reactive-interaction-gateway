# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- [API Gateway] New custom metric: `rig_proxy_requests_total`. For details see [`metrics-details.md`](docs/metrics-details.md). [#157](https://github.com/Accenture/reactive-interaction-gateway/issues/157)
- _Beta_ - Added Apache Avro support for consumer and producer as well as Kafka Schema Registry.
- [Docs] Added new set of topics in documentation about Api Gateway, even streams and scaling.
- [Docs] Added examples section to documentation website.
- [API/Proxy] Added new `response_from` option -- `http_async` together with new internal `POST` endpoint `/v1/responses`. You can send correlated response to `/v1/responses` and complete initial Proxy request. [#213](https://github.com/Accenture/reactive-interaction-gateway/issues/213)
- Implement [HTTP Transport Binding for CloudEvents v0.2](https://github.com/cloudevents/spec/blob/v0.2/http-transport-binding.md). A special fallback to "structured mode" in case the content type is "application/json" and the "ce-specversion" header is not set ensures this change is backward compatible with existing setups. [#153](https://github.com/Accenture/reactive-interaction-gateway/issues/153)
- [API/Proxy] New request body format for endpoints with `kafka` and `kinesis` targets; see [Deprecated](#Deprecated) below.

<!-- ### Changed -->

### Fixed

- Fixed a bug that caused the subscriptions endpoint to return an internal server error when running RIG in a clustered setup. [#194](https://github.com/Accenture/reactive-interaction-gateway/issues/194)
- Support for forwarding HTTP/1.1 responses over a HTTP/2 connection by dropping connection-related HTTP headers. [#193](https://github.com/Accenture/reactive-interaction-gateway/issues/193)
- [Docs] Added missing `id` field to swagger spec for `message` API.
- [Kafka] Fixed random generation of group IDs. This led to wrong partition distribution when using multiple RIG nodes. Now consumers will have the same ID which can be changed via environment variable - defaults to `rig`.
- [Proxy] When forwarding an HTTP request, the [`Host`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host) request header is now set to the `target_url` defined by the proxy configuration. [#188](https://github.com/Accenture/reactive-interaction-gateway/issues/188)
- [Docs] Fixed missing `swagger.json` file in production Docker image.
- [Proxy] Added missing CORS headers for Kafka/Kinesis target type when not using `response_from`.
- [Kafka] Fixed schema registry validation when using binary messages in Kafka consumer. [#202](https://github.com/Accenture/reactive-interaction-gateway/issues/202)

### Deprecated

- [Proxy] Endpoints configured with target `kafka` or `kinesis` now expect a different body format (that is, the previous format is deprecated). This aligns the request body format with the other endpoints that accept CloudEvents.

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

<!-- ### Removed -->

<!-- ### Security -->

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

- [Proxy] Parsing of JSON files in proxy module - `api.id` was expected to be an atom, but when using files it's a string.
- [Kinesis] Support for CloudEvents versions 0.1 and 0.2.
- [Docs] Fixed channels example with latest RIG API changes.
- [Docs] Fixed sse/ws examples to use JWT inferred subscriptions correctly.

## [2.1.0] - 2019-02-15

### Added

- Prometheus monitoring endpoint. [#96](https://github.com/Accenture/reactive-interaction-gateway/issues/96)
- The proxy configuration can now also be passed as a JSON string. This allows to run the Docker image in environments where mounting a file in a container is not possible. [#159](https://github.com/Accenture/reactive-interaction-gateway/issues/159)

### Removed

- Rate limiting. [#144](https://github.com/Accenture/reactive-interaction-gateway/issues/144)

## [2.0.2] - 2019-01-20

### Fixed

- Upgraded a dependency to fix the Docker build. [#149](https://github.com/Accenture/reactive-interaction-gateway/issues/149)

## [2.0.1] - 2019-01-20

### Fixed

- A library upgrade caused idle SSE connections to time out after 60 seconds. This timeout is now disabled. [PR #148](https://github.com/Accenture/reactive-interaction-gateway/pull/148)

## [2.0.0] - 2019-01-16

### Added

- HTTP/2 and HTTPS support. [#34](https://github.com/Accenture/reactive-interaction-gateway/issues/34)
- The SSE and WebSocket endpoints now take a "subscriptions" parameter that allows to create (manual) subscriptions (JSON encoded list). This has the same effect as establishing a connection and calling the subscriptions endpoint afterwards.
- OpenAPI (Swagger) documentation for RIG's internal API. [#116](https://github.com/Accenture/reactive-interaction-gateway/issues/116)
- Support for the CloudEvents v0.2 format. [#112](https://github.com/Accenture/reactive-interaction-gateway/issues/112)
- [Proxy] In API definitions regular expressions can now be used to define matching request paths. Also, request paths can be rewritten (see [api.ex](apps/rig_inbound_gateway/lib/rig_inbound_gateway/api_proxy/api.ex) for an example). [#88](https://github.com/Accenture/reactive-interaction-gateway/issues/88)

### Changed

- The SSE and WebSocket endpoints' "token" parameter is renamed to "jwt" (to not confuse it with the connection token).
- [Proxy] When forwarding requests, RIG related meta data (e.g. correlation ID) in CloudEvents is now put into an object under the top-level key "rig". Note that in terms of the current [CloudEvents 0.2](https://github.com/cloudevents/spec/blob/v0.2/spec.md) specification this makes "rig" an [extension](https://github.com/cloudevents/spec/blob/v0.2/primer.md#cloudevent-attribute-extensions). Also, all RIG related keys have been renamed from snake_case to camelCase.
- [Proxy] Previously API definitions for proxy were turning on security check for endpoints by `not_secured: false` which is a bit confusing -- changed to more readable form `secured: true`.
- [Auth] No longer assumes the "Bearer" token type when no access token type is prepended in the Authorization header. Consequently, a client is expected to explicitly use "Bearer" for sending its JWT authorization token. More more details, see [RFC 6749](https://tools.ietf.org/html/rfc6749#section-7.1).
- All events that RIG creates are now in CloudEvents v0.2 format (before: CloudEvents v0.1).
- [Proxy] When using Kafka or Kinesis as the target, connection related data is added to the event before publishing it to the respective topic/partition. With the introduction of CloudEvents v0.2, RIG now follows the CloudEvent extension syntax with all fields put into a common top-level object called "rig". Additionally, the object's field names have been changed slightly to prevent simple mistakes like case-sensitivity issues. Also, the expected request body fields have been renamed to be more descriptive. To that end, usage information returned as plaintext should help the API user in case of a Bad Request.

<!-- ### Deprecated -->

<!-- ### Removed -->

### Fixed

- Extractor configuration reload
- [Inbound] Fixed response to CORS related preflight request.

<!-- ### Security -->

## [2.0.0-beta.2] - 2018-11-09

### Added

- [Auth] JWT now supports RS256 algorithm in addition to HS256. [#84](https://github.com/Accenture/reactive-interaction-gateway/issues/84)
- [Outbound] Support Kafka SSL and SASL/Plain authentication. [#79](https://github.com/Accenture/reactive-interaction-gateway/issues/79)
- [Inbound] Add new endpoints at `/_rig/v1/` for subscribing to CloudEvents using SSE/WS, for creating subscriptions to specific event types, and for publishing CloudEvents. [#90](https://github.com/Accenture/reactive-interaction-gateway/issues/90)
- [Inbound] Expose setting for proxy response timeout. [#91](https://github.com/Accenture/reactive-interaction-gateway/issues/91)
- [Inbound] Subscriptions inference using JWT on SSE/WS connection and subscription creation. [#90](https://github.com/Accenture/reactive-interaction-gateway/issues/90)
- [Inbound] Allow publishing events to Kafka and Kinesis via reverse-proxy HTTP calls. Optionally, a response can be waited for (using a correlation ID).
- [Docs] Simple event subscription examples for SSE and WS.
- [Outbound] Kafka/Kinesis firehose - set topic/stream to consume and invoke HTTP request when event is consumed.

### Changed

- [Inbound] SSE heartbeats are now sent as comments rather than events, and events without data carry an empty data line to improve cross-browser compatibility. [#64](https://github.com/Accenture/reactive-interaction-gateway/issues/64)
- [Docs] General documentation and outdated info.

### Removed

- [Inbound] Previous SSE/WS communication via Phoenix channels.
- Events that don't follow the CloudEvents spec are no longer supported (easy migration: put your event in a CloudEvent's `data` field).

### Fixed

- [Inbound] Flaky tests in `router_test.exs` -- switching from `Bypass` to `Fakeserver`. [#74](https://github.com/Accenture/reactive-interaction-gateway/issues/74)
- [Docs] Channels example. [#64]https://github.com/Accenture/reactive-interaction-gateway/issues/64

## [2.0.0-beta.1] - 2018-06-21

### Added

- [Outbound] Amazon Kinesis integration. [#27](https://github.com/Accenture/reactive-interaction-gateway/issues/27)
- [Misc] Use lazy logger calls for debug logs.
- [Misc] Format (most files) using Elixir 1.6 formatter.
- [API/Outbound] Add new endpoint `POST /messages` for sending messages (=> Kafka is no longer a hard dependency).
- [Docs] Add a dedicated developer guide.
- [Deploy] Release configuration in `rel/config.exs` and custom `vm.args` (based on what distillery is using). [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
- [Deploy] Production configuration for peerage to use DNS discovery. [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
- [Rig] Module for auto-discovery, using `Peerage` library. [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
- [Deploy] Kubernetes deployment configuration file. [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
- [Misc] Smoke tests setup and test cases for API Proxy and Kafka + Phoenix messaging. [#42](https://github.com/Accenture/reactive-interaction-gateway/pull/42)
- [Outbound] Kafka consumer ready check utility function. [#42](https://github.com/Accenture/reactive-interaction-gateway/pull/42)
- [Docs] List of all environment variables possible to set in `guides/operator-guide.md`. [#36](https://github.com/Accenture/reactive-interaction-gateway/pull/36)
- [Rig] Possibility to set logging level with env var `LOG_LEVEL`. [#49](https://github.com/Accenture/reactive-interaction-gateway/pull/49)
- [Deploy] Variations of Dockerfiles - basic version and AWS version. [#44](https://github.com/Accenture/reactive-interaction-gateway/pull/44)
- [Deploy] Helm deployment chart. [#59](https://github.com/Accenture/reactive-interaction-gateway/pull/59)
- [Inbound] Proxy is now able to do request header transformations. [#76](https://github.com/Accenture/reactive-interaction-gateway/pull/76)

### Changed

- [Api] Endpoint for terminating a session no longer contains user id in path.
- [Misc] Convert to umbrella project layout.
- [Docs] Move documentation from `doc/` to `guides/` as the former is the default for ex_doc output.
- [Inbound] Revised request logging (currently Kafka and console as backends).
- [Inbound] Disable WebSocket timeout. [#58](https://github.com/Accenture/reactive-interaction-gateway/pull/58)
- [Deploy] Dockerfile to use custom `vm.args` file & removed `mix release.init` step. [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)

### Fixed

- [Inbound] Make presence channel respect `JWT_USER_FIELD` setting (currently hardcoded to "username")
- [Inbound] Set proper environment variable for Phoenix server `INBOUND_PORT` - [#38](https://github.com/Accenture/reactive-interaction-gateway/pull/38)
- [API] Set proper environment variable for Phoenix server `API_PORT` - [#38](https://github.com/Accenture/reactive-interaction-gateway/pull/38)
- [Examples] Channels example fixed to be compatible with version 2.0.0 [#40](https://github.com/Accenture/reactive-interaction-gateway/pull/40)
- [Inbound] User defined query auth values are no longer overridden by `JWT` auth type
- [Outbound] Handle content-type correctly - [#61](https://github.com/Accenture/reactive-interaction-gateway/pull/61)
- [Inbound] More strict regex match for routes in proxy - [#76](https://github.com/Accenture/reactive-interaction-gateway/pull/76)
- [Inbound] Downcased response headers to avoid duplicates in proxy - [#76](https://github.com/Accenture/reactive-interaction-gateway/pull/76)

## [1.1.0] - 2018-01-11

### Added

- [Deploy] Basic Travis configuration. [#17](https://github.com/Accenture/reactive-interaction-gateway/pull/17)
- [Docs] Configuration ADR document. [#19](https://github.com/Accenture/reactive-interaction-gateway/pull/19)
- [Docs] Websocket and SSE channels example. [#22](https://github.com/Accenture/reactive-interaction-gateway/pull/22)
- [Deploy] Maintain changelog file. [#25](https://github.com/Accenture/reactive-interaction-gateway/pull/25)

### Changed

- [Config] Increase default rate limits. [#16](https://github.com/Accenture/reactive-interaction-gateway/pull/16)
- [Kafka] Make producing of Kafka messages in proxy optional (and turned off by default). [#21](https://github.com/Accenture/reactive-interaction-gateway/pull/21)

### Fixed

- [Config] Fix Travis by disabling credo rule `Design.AliasUsage`. [#18](https://github.com/Accenture/reactive-interaction-gateway/pull/18)

## 1.0.0 - 2017-11-09

### Added

- [Docs] Add `mix docs` script to generate documentation of code base. [#6](https://github.com/Accenture/reactive-interaction-gateway/pull/6)
- [Docs] Add ethics documentation such as code of conduct and contribution guidelines. [#6](https://github.com/Accenture/reactive-interaction-gateway/pull/6)

### Changed

- [Config] Update configuration to be able to modify almost anything by environment variables on RIG start. [#5](https://github.com/Accenture/reactive-interaction-gateway/pull/5)
- [Deploy] Rework Dockerfile to use multistage approach for building RIG Docker image. [#9](https://github.com/Accenture/reactive-interaction-gateway/pull/9)
- [Config] Update entire code base to use `rig` keyword. [#13](https://github.com/Accenture/reactive-interaction-gateway/pull/13)

### Removed

- [Config] Disable Origin checking. [#12](https://github.com/Accenture/reactive-interaction-gateway/pull/12)

[unreleased]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.1.1...HEAD
[2.1.1]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.1.0...2.1.1
[2.1.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.2...2.1.0
[2.0.2]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.1...2.0.2
[2.0.1]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.0-beta.2...2.0.0
[2.0.0-beta.2]: https://github.com/Accenture/reactive-interaction-gateway/compare/2.0.0-beta.1...2.0.0-beta.2
[2.0.0-beta.1]: https://github.com/Accenture/reactive-interaction-gateway/compare/1.1.0...2.0.0-beta.1
[1.1.0]: https://github.com/Accenture/reactive-interaction-gateway/compare/1.0.0...1.1.0
