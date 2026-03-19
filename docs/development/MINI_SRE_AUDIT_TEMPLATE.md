---
type: template
name: Mini SRE Audit
phase: Verify
produces: SRE QE failure mode catalog and test cases
---

# Mini SRE Audit: [Component/Integration Name]

**Date:** YYYY-MM-DD
**Auditor:** SRE QE sub-persona
**Trigger:** New component | First integration | State transition
**Duration:** ~15 minutes

---

## Failure Modes Identified

| # | Failure Mode | Severity | Current Behavior | Recommended Fix |
|---|---|---|---|---|
| 1 | {e.g., nil input to render function} | P0/P1/P2 | {e.g., silent skip, no output} | {e.g., return error + loading state} |
| 2 | | | | |
| 3 | | | | |

---

## Nil Safety

- [ ] All pointer/optional fields have explicit nil handling
- [ ] Nil produces visible feedback (error message, loading state), not silent skip
- [ ] Zero-value structs behave correctly (not just non-nil structs)
- [ ] Map lookups check for key existence before use

## Error Surfacing

- [ ] Errors propagated to caller (not swallowed)
- [ ] Error states are visually distinct from loading/empty states
- [ ] Error messages include enough context to diagnose (not just "error occurred")
- [ ] Errors logged at appropriate level (warn for recoverable, error for unrecoverable)

## Recovery

- [ ] Component can recover from transient errors without restart
- [ ] Manual recovery path exists (refresh key, retry button, restart command)
- [ ] Recovery does not require full system restart (component-level recovery)
- [ ] After recovery, component returns to correct state (not stale/partial state)

## Integration Points (if applicable)

- [ ] Timeout configured for all external calls
- [ ] Graceful degradation when dependency unavailable (not crash/hang)
- [ ] Connection failure produces meaningful error (not generic timeout)
- [ ] Retry logic has backoff and max attempts (not infinite retry)

## State Transitions (if applicable)

- [ ] All state transitions are tested (loading → ready → error → recovery)
- [ ] No stuck intermediate states (loading that never resolves)
- [ ] Watchdog/timeout exists for long-running state transitions
- [ ] Concurrent state transitions don't corrupt state

---

## Findings Summary

**Critical (P0):** {count} — must fix before sprint close
**High (P1):** {count} — fix this sprint or next
**Medium (P2):** {count} — add to backlog

### Test Cases Generated

Each failure mode above should generate at least one test case:

| Failure Mode # | Test File | Test Description |
|---|---|---|
| 1 | {path} | {what the test verifies} |

---

## Trigger Conditions

Two-tier trigger system — automatic for foundational components, IE-triggered for complex components with observed resilience signals.

### Tier 1 — Automatic (always fires)

Components with state, external dependencies, or integration points:

1. **Stateful components** — Manages state transitions (loading → ready → error → recovery)
2. **First integration of 2+ components** — Wiring, protocol boundaries, data flow between modules
3. **External dependency components** — Network calls, filesystem I/O, database access, external services

Pure utility functions, stateless transformers, and type definitions do NOT trigger automatic audits.

### Tier 2 — IE-triggered (scalpel)

Complex components that cross a complexity threshold, but ONLY when the IE agent has observed resilience failures in other components and identifies similar patterns. IE connects the dots: "Component X had a nil-at-boundary failure. Component Y has similar boundary characteristics. Triggering SRE audit on Y."

This is targeted probing informed by real failure observations — not blanket coverage.

The SRE QE sub-persona owns this audit. Tier 1 activates automatically. Tier 2 activates on IE andon signal.
