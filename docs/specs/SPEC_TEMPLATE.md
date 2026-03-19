---
type: template
name: Specification
phase: Specification
produces: Feature specification document
---

# SPEC-{ID}: {Title}

**Status:** Planning | In Progress | Complete
**Sprint:** {N}
**Priority:** P0 | P1 | P2
**Review Tier:** Minimal | Standard | Full

---

## Summary

{1-3 sentences}

## Motivation

{Why this is needed — problem statement + current state}

## User Story

As a {specific actor}, I want to {capability} so that {business value}.

## Requirements

### FR-1: {Title}

{Description with scope and constraints}

### FR-2: {Title}

{Description}

## Non-Functional Requirements

- NFR-1: {Measurable target, e.g., "<100ms p95 latency"}

## Acceptance Criteria

- AC-1: {Independently verifiable outcome}
- AC-2: {Independently verifiable outcome}

## Gherkin Scenarios

```gherkin
Feature: {Feature name}
  Scenario: {Happy path}
    Given {realistic precondition}
    When {action}
    Then {verifiable outcome}
```

## Design

{Technical approach — interfaces, data flow, key decisions}

## Test Plan

{Test categories with expected counts}

## Dependencies

{What must exist before this spec can be implemented}
