# 5. Maintain changelog

Date: 14/12/2017

## Status

Accepted

## Context

We need to track what changes have been made to RIG and make it clear to everyone. It should also help with identifying of issues that may be caused by changes in the past.

## Decision

We decided to use `CHANGELOG.md` to have it as a single source of truth to what happened in RIG. Every submitted Pull Request will contain update to this file as well. By this everyone can clearly see which version has which features or fixes.

## Consequences

Every contributor submitting Pull Request has to also update `CHANGELOG.md` file and keep everything up to date. Update has to be done in form of `[Type of change e.g. Config, Kafka, .etc] Short description what it is all about - [#PR-ID-NUMBER](link to pull request)`, please put your change under suitable section - changed, added, fixed, removed, deprecated
