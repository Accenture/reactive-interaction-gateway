# Changelog

[Unreleased]

- Changed
  - [Config] Increase default rate limits - [#16](https://github.com/Accenture/reactive-interaction-gateway/pull/16)
  - [Kafka] Make producing of Kafka messages in proxy optional (and turned off by default) - [#21](https://github.com/Accenture/reactive-interaction-gateway/pull/21)
  - [Deploy] Dockerfile to use custom `vm.args` file & removed `mix release.init` step - []()

- Added
  - [Deploy] Basic Travis configuration - [#17](https://github.com/Accenture/reactive-interaction-gateway/pull/17)
  - [Docs] Configuration ADR document - [#19](https://github.com/Accenture/reactive-interaction-gateway/pull/19)
  - [Docs] Websocket and SSE channels example - [#22](https://github.com/Accenture/reactive-interaction-gateway/pull/22)
  - [Deploy] Maintain changelog file - [#25](https://github.com/Accenture/reactive-interaction-gateway/pull/25)
  - [Deploy] Release configuration in `rel/config.exs` and custom `vm.args` (based on what distillery is using) - []()
  - [Deploy] Production configuration for peerage to use DNS discovery - []()
  - [Deploy] Module for auto-discovery, using `Peerage` library - []()
  - [Deploy] Kubernetes deployment configuration file - []()

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