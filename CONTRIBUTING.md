# Contributing to the Reactive Interaction Gateway

Thanks for taking the time to contribute!

The following is a set of guidelines for contributing to RIG and its packages, which are hosted
in the [Accenture Organization](https://github.com/accenture) on GitHub. These are mostly
guidelines, not rules. Use your best judgment, and feel free to propose changes to this document
in a pull request.

## Code of Conduct

This project and everyone participating in it is governed by our
[Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.
Please report unacceptable behavior to Kevin Bader, who is the current project maintainer.

## I just have a question!

We have a [mailing list](https://groups.google.com/d/forum/reactive-interaction-gateway) where
the community chimes in with helpful advice if you have questions.

## What should I know before I get started?

You can
- generate documentation with `mix docs`,
- run unit tests with `mix test` and see the test coverage with
  `mix coveralls.html`, which generates a file at `doc/excoveralls.html`,
- run the linter with `mix credo --strict`.
- run smoke tests with `docker-compose -f smoke_tests.docker-compose.yml up -d --build`
  - to see smoke tests logs run `docker logs -f rig`
  - to re-run smoke tests without re-creating entire environment run `docker-compose -f smoke_tests.docker-compose.yml up --no-deps --build rig`

We follow the [standard GitHub workflow](https://guides.github.com/introduction/flow/).
Before submitting a PR,
- please write tests,
- make sure you run all tests and check the linter (credo) for warnings.
- update `CHANGELOG.md` file with your current change in form of `[Type of change e.g. Config, Kafka, .etc] Short description what it is all about - [#PR-ID-NUMBER](link to pull request)`, please put your change under suitable section - changed, added, fixed, removed, deprecated

An overview of the directory structure:
- `lib/rig`
  Features are implemented here, unless they're web-related
  - `lib/rig/application.ex`
    Application entry point
  - `lib/rig/api_proxy/proxy.ex`
    Reverse proxy implementation
  - `lib/rig/blacklist*`
    Blacklisting tokens allows for kicking out users immediately, ignoring token expiration
  - `lib/rig/kafka*`
    Integration with Kafka
  - `lib/rig/rate_limit*`
    The feature limits the amount of connections per second, per target-endpoint and source-IP
- `lib/rig_web`
  Web-related stuff, like controllers and socket-handlers
  - `lib/rig_web/presence*`
    Code related to handling active frontend connections

### Design Decisions
When we make a significant decision in how to write code, or how to maintain the project and
what we can or cannot support, we will document it using
[Architecture Decision Records (ADR)](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions).
Take a look at the [doc/architecture/decisions](doc/architecture/decisions/) directory for
existings ADRs. If you have a question around how we do things, check to see if it is documented
there. If it is *not* documented there, please ask us - chances are you're not the only one
wondering. Of course, also feel free to challenge the decisions by starting a discussion on the
mailing list.
