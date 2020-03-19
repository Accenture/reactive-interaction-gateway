---
id: rig-dev-guide
title: Developer's Guide to the Reactive Interaction Gateway
sidebar_label: Developer's Guide
---

You'd like to mess with the code? Great! To get started, install Elixir and the Mix build tool on your machine. You can either follow the [instructions on the Elixir website](https://elixir-lang.org/install.html), or use [kiex](https://github.com/taylor/kiex) to install and manage Elixir runtimes. Kiex is recommended for development, because it allows you to jump to definitions inside the Elixir source code, plus you can checkout upcoming Elixir versions easily.

With Elixir installed, do this:

- Install dependencies with `mix deps.get`
- Start Phoenix endpoint with `mix phx.server`

RIG doesn't come with a status website, but if you like to you can check its health endpoint:

```bash
$ curl localhost:4000
{"message":"Route is not available"}
$ curl localhost:4010/health
OK
```

Additional notes:

- You can run tests with `mix test`. See [CONTRIBUTING.md](https://github.com/Accenture/reactive-interaction-gateway/blob/master/CONTRIBUTING.md) for more details.
- When debugging multi-node features, it's helpful to run the (named) nodes in `iex` sessions
  using `iex --sname nodename -S mix`.

Our conventions are documented in [`guides/architecture/decisions/`](https://github.com/Accenture/reactive-interaction-gateway/blob/master/guides/architecture/decisions/). See [0001-record-architecture-decisions.md](https://github.com/Accenture/reactive-interaction-gateway/blob/master/guides/architecture/decisions/0001-record-architecture-decisions.md) for more details.

## Project Layout

Run `mix docs` to see the source documentation. The module descriptions should make the code structure obvious; if they don't, please open an issue describing what you were looking for but couldn't find. Also, updates to the (source code) documentation are appreciated!

## Incrementing Elixir and OTP versions

To have the project use a newer Elixir version, make sure to change the following locations:

- `.travis.yml`: Update the Elixir and OTP versions in the `.elixir-env` section.
- `Dockerfile`, `aws.dockerfile`, `smoke_tests.dockerfile`: Make sure to change the `FROM` image tag for both the build image (elixir:...-alpine) as well as the runtime image (erlang:...-alpine). If the Erlang runtime (ERTS) in the runtime image doesn't match the ERTS version in the build image, chances are the built image won't work due to missing libraries. Because of this, it's best to use the most recent versions for both images when upgrading - they should always be compatible.
- `version`: Again, make sure both the Elixir and the OTP versions match what you have used in the previous steps.

## Releasing a new version

- Increment `rig` version in the [version](../version) file
- In [CHANGELOG.md](https://github.com/Accenture/reactive-interaction-gateway/blob/master/CHANGELOG.md), rename `[Unreleased]` and add a corresponding link to the bottom of the file
- Create a signed Git tag either using `git -s` or by creating a release using the Github UI

## Test Tags

We use `tag`s to group tests together. Often, it makes sense to assign more than one tag to a test case.

`@tag` | When to use it?
------ | ---------------
`:avro` | Integration tests that require a running Avro schema registry.
`:kafka` | Integration tests that require a running Kafka broker.
`:kinesis` | Integration tests that require an active Kinesis stream.
`:smoke` | Quick integration test that is designed to catch obvious integration problems.
