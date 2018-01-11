# Changelog

## v2.0.0-dev

- TODO
  - kafka message has user field but what about userfield in http post for POST /messages
  - socket authentication can be commented out with all tests passing :/
  - kafka.sup does not respect KAFKA_ENABLED=0 anymore
  - logging to Kafka is gone... logger app with kafka module?

- Changed
  - [Misc] Convert to umbrella project layout
  - [Docs] Move documentation from `doc/` to `guides/` as the former is the default for ex_doc output

- Added
  - [Misc] Use lazy logger calls for debug logs
  - [Misc] Format (most files) using Elixir 1.6 formatter
  - [API/Outbound] Add new endpoint `POST /messages` for sending messages (=> Kafka is no longer a hard dependency)
  - [Docs] Add a dedicated developer guide

- Fixed
  - [Inbound] Make presence channel respect `JWT_USER_FIELD` setting (currently hardcoded to "username")

- Deprecated

## v1.1.0 (January 11, 2018)

- Changed
  - [Config] Increase default rate limits - [#16](https://github.com/Accenture/reactive-interaction-gateway/pull/16)
  - [Kafka] Make producing of Kafka messages in proxy optional (and turned off by default) - [#21](https://github.com/Accenture/reactive-interaction-gateway/pull/21)

- Added
  - [Deploy] Basic Travis configuration - [#17](https://github.com/Accenture/reactive-interaction-gateway/pull/17)
  - [Docs] Configuration ADR document - [#19](https://github.com/Accenture/reactive-interaction-gateway/pull/19)
  - [Docs] Websocket and SSE channels example - [#22](https://github.com/Accenture/reactive-interaction-gateway/pull/22)
  - [Deploy] Maintain changelog file - [#25](https://github.com/Accenture/reactive-interaction-gateway/pull/25)

- Fixed
  - [Config] Fix Travis by disabling credo rule `Design.AliasUsage` - [#18](https://github.com/Accenture/reactive-interaction-gateway/pull/18)

## v1.0.0 (November 9, 2017)

- Changed
  - [Config] Update configuration to be able to modify almost anything by environment variables on RIG start - [#5](https://github.com/Accenture/reactive-interaction-gateway/pull/5)
  - [Deploy] Rework Dockerfile to use multistage approach for building RIG Docker image - [#9](https://github.com/Accenture/reactive-interaction-gateway/pull/9)
  - [Config] Update entire code base to use `rig` keyword - [#13](https://github.com/Accenture/reactive-interaction-gateway/pull/13)

- Added
  - [Docs] Add `mix docs` script to generate documentation of code base - [#6](https://github.com/Accenture/reactive-interaction-gateway/pull/6)
  - [Docs] Add ethics documentation such as code of conduct and contribution guidelines - [#6](https://github.com/Accenture/reactive-interaction-gateway/pull/6)

- Removed
  - [Config] Disable Origin checking - [#12](https://github.com/Accenture/reactive-interaction-gateway/pull/12)
