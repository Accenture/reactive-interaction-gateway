# 2. Don't check for FunctionClauseError in tests

Date: 15/05/2017

## Status

Accepted

## Context

Typically, a module API filters possible inputs implicitly by making use of pattern matching. For instance, a GenServer that only handles `:test` messages might have a method similar to `handle_call(:test, _, _)`.

Writing tests that assure that pattern matching works with the given signature (e.g., by checking that `handle_call(:illegal, 0, 0)` fails) has drawbacks:

* Asserting that the process `exit`s with a `FunctionClauseError` is not straight-forward.
* Arguably, one of the ideas of pattern matching in function signatures is to save on testing negative cases in the first place.
* Often, testing for missing function clauses make tests needlessly brittle.

Still, there is the case of regression testing, e.g., making sure that there will never exist a handler for other messages. We think that such a restriction is rarely required, though.

## Decision

Except for regression tests, tests should not aim at triggering `FunctionClauseError`s.

## Consequences

We save on writing test code, and tests are potentially less brittle.
