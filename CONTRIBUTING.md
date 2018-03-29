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

Since this is a standard mix project, typical mix commands work as expected:

- Generate documentation with `mix docs`.
- Run unit tests with `mix test` and see the test coverage with
  `mix coveralls.html`, which generates a file at `doc/excoveralls.html`.

For static analysis, we use [credo](https://github.com/rrrene/credo):

- Run the linter with `mix credo --strict`.

There is a smoke-test test-suite that can be started with a mix task as well:

- Run smoke tests with `mix smoke_test`.
  - Alternatively, you can run the tests directly with `docker-compose -f smoke_tests.docker-compose.yml up -d --build`.
  - To see smoke tests logs run `docker logs -f rig`.
  - To re-run smoke tests without re-creating entire environment run `docker-compose -f smoke_tests.docker-compose.yml up --no-deps --build rig`.

We follow the [standard GitHub workflow](https://guides.github.com/introduction/flow/).
Before submitting a PR:

- Please write tests.
- Make sure you run all tests and check the linter (credo) for warnings.
- Think about whether it makes sense to document the change in some way. For smaller, internal changes, inline documentation might be sufficient (moduledoc), while more visible ones might warrant a change to the [developer's guide](guides/developer-guide.md), the [operator's guide](guides/operator-guide.md) or the [README](./README.md).
- Update `CHANGELOG.md` file with your current change in form of `[Type of change e.g. Config, Kafka, .etc] Short description what it is all about - [#NUMBER](link to issue or pull request)`, and choose a suitable section (i.e., changed, added, fixed, removed, deprecated).

### Design Decisions

When we make a significant decision in how to write code, or how to maintain the project and
what we can or cannot support, we will document it using
[Architecture Decision Records (ADR)](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions).
Take a look at the [doc/architecture/decisions](doc/architecture/decisions/) directory for
existings ADRs. If you have a question around how we do things, check to see if it is documented
there. If it is *not* documented there, please ask us - chances are you're not the only one
wondering. Of course, also feel free to challenge the decisions by starting a discussion on the
mailing list.
