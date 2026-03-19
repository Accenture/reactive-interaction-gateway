---
type: template
name: Session Checkpoint
phase: Build
produces: Mid-session checkpoint document
---

# Checkpoint: Sprint {N} — Session {M}

**Date:** YYYY-MM-DD
**Branch:** `feature/{branch-name}`
**Status:** Mid-Sprint / Sprint Boundary

---

## In-Flight Work Items

| WI       | Description   | Status      | % Complete | Notes                         |
| -------- | ------------- | ----------- | ---------- | ----------------------------- |
| WI-{N}.1 | {Description} | In Progress | ~70%       | {What remains}                |
| WI-{N}.2 | {Description} | Pending     | 0%         | {Blocked by / ready to start} |

## Partial Implementations

| File                     | What's Done                           | What Remains                              |
| ------------------------ | ------------------------------------- | ----------------------------------------- |
| `src/module/new-file.ts` | Core logic implemented, tests written | Error handling for edge case X            |
| `src/module/existing.ts` | Modified constructor for DI           | Need to update 3 test files with new mock |

## Known Issues / Blockers

| Issue         | Severity                | Investigation State                              |
| ------------- | ----------------------- | ------------------------------------------------ |
| {Description} | Blocking / Non-blocking | {What you've tried, what you know, error output} |

## Environment State

- **Branch:** `feature/{name}` (N commits ahead of `dev`)
- **Uncommitted changes:** {Yes/No — if yes, list files}
- **Running services:** {List any services that must be running}
- **Config overrides:** {Any env vars or config changes needed}

## Next-Step Instructions

When resuming this session:

1. {First thing to do — e.g., "Run npm test to verify baseline"}
2. {Second thing — e.g., "Continue WI-N.1: implement error handling in src/module/new-file.ts"}
3. {Any context that won't be in the code — e.g., "The mock cascade from adding the new DI param affects 5 test files, list: ..."}

---

**This checkpoint supplements the Session Boundary Protocol. Read this BEFORE reading DELIVERY_PLAN.md when resuming.**
