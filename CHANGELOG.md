# Changelog

## v2.0.0-dev

- Changed
  - [Misc] Convert to umbrella project layout
  - [Docs] Move documentation from `doc/` to `guides/` as the former is the default for ex_doc output
  - [Inbound] Revised request logging (currently Kafka and console as backends)
  - [Deploy] Dockerfile to use custom `vm.args` file & removed `mix release.init` step - [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)

- Added
  - [Misc] Use lazy logger calls for debug logs
  - [Misc] Format (most files) using Elixir 1.6 formatter
  - [API/Outbound] Add new endpoint `POST /messages` for sending messages (=> Kafka is no longer a hard dependency)
  - [Docs] Add a dedicated developer guide
  - [Deploy] Release configuration in `rel/config.exs` and custom `vm.args` (based on what distillery is using) - [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
  - [Deploy] Production configuration for peerage to use DNS discovery - [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
  - [Rig] Module for auto-discovery, using `Peerage` library - [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)
  - [Deploy] Kubernetes deployment configuration file - [#29](https://github.com/Accenture/reactive-interaction-gateway/pull/29)

- Fixed
  - [Inbound] Make presence channel respect `JWT_USER_FIELD` setting (currently hardcoded to "username")
  - [Inbound] Set proper environment variable for Phoenix server `INBOUND_PORT` - [#38](https://github.com/Accenture/reactive-interaction-gateway/pull/38)
  - [API] Set proper environment variable for Phoenix server `API_PORT` - [#38](https://github.com/Accenture/reactive-interaction-gateway/pull/38)
  - [Examples] Channels example fixed to be compatible with version 2.0.0 [#]()

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
