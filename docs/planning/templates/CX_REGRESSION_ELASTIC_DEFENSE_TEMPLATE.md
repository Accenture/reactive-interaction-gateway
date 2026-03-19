---
type: cx-regression-elastic
status: template
sprint: "{SPRINT_ID}"
profile: elastic-defense
partitions: [visual-qa, interaction, content, performance]
---

# CX Regression Checklist — Elastic Defense Variant

**Auditor:** CX Designer persona
**Date:** {DATE}
**Scope:** Full CX regression with agent-partitioned execution
**Method:** Elastic defense — partition checklist across agent runs, consolidate findings

---

## Elastic Defense Model

This variant splits the CX regression into independent partitions that can be executed by separate agent runs (or separate personas within a single session). Each partition is self-contained and produces its own findings. A final consolidation step merges all partition findings into a single assessment.

### Separation Rules

1. **No cross-partition dependencies** — each partition can run independently and in any order
2. **No shared mutable state** — partitions read from the codebase but do not modify shared artifacts until consolidation
3. **Partition boundary = concern boundary** — visual QA does not evaluate performance, interaction does not evaluate content variety
4. **Findings use a common schema** — every partition produces findings in the same table format for clean merging
5. **Consolidation is a separate step** — do not merge findings inline; run all partitions first, then consolidate

### Finding Schema (All Partitions)

Every finding must use this format:

| Field | Format |
|-------|--------|
| ID | `{PARTITION}-{N}` (e.g., `VQA-1`, `PERF-3`) |
| Severity | P0 (blocking) / P1 (high) / P2 (minor) / P3 (cosmetic) |
| Section | Which checklist item |
| Description | What was observed |
| Expected | What should happen |
| Status | Open / Fixed / Accepted |

---

## Partition A: Visual QA

**Partition ID:** `VQA`
**Focus:** Layout, rendering, color, typography, borders, visual hierarchy

### A1. Layout Integrity
- [ ] All panels/views render without overlap
- [ ] Visual hierarchy is clear (primary, secondary, tertiary elements)
- [ ] Borders and dividers align correctly
- [ ] No orphaned or floating elements

### A2. Responsive Behavior
- [ ] Minimum supported size renders without crash
- [ ] Each breakpoint tier renders correctly
- [ ] Content reflows or degrades gracefully at each tier
- [ ] No content clipped without scroll or truncation indicator

### A3. Color and Contrast
- [ ] Color palette applied consistently across all surfaces
- [ ] No undefined or placeholder colors in rendered output
- [ ] Sufficient contrast for all text elements
- [ ] Color conveys meaning consistently (e.g., error = red, success = green)

### A4. Typography and Text
- [ ] No text overflow or mid-word truncation
- [ ] Alignment consistent within each surface
- [ ] Special characters render correctly
- [ ] Empty text states handled (no blank gaps)

**Partition A Findings:**

| ID | Severity | Section | Description | Expected | Status |
|----|----------|---------|-------------|----------|--------|
| | | | | | |

---

## Partition B: Interaction and State

**Partition ID:** `INT`
**Focus:** Input handling, state transitions, navigation, user flow

### B1. Input Handling
- [ ] All documented key bindings respond correctly
- [ ] No unhandled key presses cause errors
- [ ] Input feedback is immediate (no perceived lag)
- [ ] Help text accurately describes available inputs

### B2. State Transitions
- [ ] Each state change produces correct visual update
- [ ] No ghost states or stale renders after transition
- [ ] Back/undo transitions restore previous state cleanly
- [ ] Rapid state changes do not corrupt display

### B3. Navigation Flow
- [ ] User can reach all documented views
- [ ] No dead-end states (always a way back or forward)
- [ ] Navigation order is logical and consistent
- [ ] Current location is always indicated

### B4. Error Recovery
- [ ] Error states display actionable messages
- [ ] Recovery from error returns to a usable state
- [ ] Repeated errors do not accumulate artifacts
- [ ] Missing data produces empty state, not crash

**Partition B Findings:**

| ID | Severity | Section | Description | Expected | Status |
|----|----------|---------|-------------|----------|--------|
| | | | | | |

---

## Partition C: Content and Narrative

**Partition ID:** `CNT`
**Focus:** Dynamic content, text variety, narrative elements, content correctness

### C1. Content Variety
- [ ] Empty state (zero items) renders correctly
- [ ] Single item renders correctly
- [ ] Typical volume renders correctly
- [ ] Maximum expected volume renders without breakage
- [ ] Overflow handling works (scroll, truncation, pagination)

### C2. Dynamic Text
- [ ] Variable-length text does not break layout
- [ ] Long strings are handled (truncation or wrap)
- [ ] Numeric values format correctly
- [ ] Date/time values format correctly

### C3. Narrative / Contextual Content (if applicable)
- [ ] Narrative text is contextually appropriate
- [ ] No placeholder or template text visible in output
- [ ] Tone is consistent across surfaces
- [ ] Content updates when underlying state changes

**Partition C Findings:**

| ID | Severity | Section | Description | Expected | Status |
|----|----------|---------|-------------|----------|--------|
| | | | | | |

---

## Partition D: Performance

**Partition ID:** `PERF`
**Focus:** Render speed, responsiveness, resource usage

### D1. Render Performance
- [ ] Initial render completes within performance contract
- [ ] Subsequent renders (state changes) meet contract
- [ ] No visible flicker or redraw artifacts
- [ ] Smooth animation (if applicable) — no dropped frames

### D2. Input Responsiveness
- [ ] Key press to visual response within contract
- [ ] No input buffering or dropped inputs
- [ ] Performance stable over extended use (no degradation)

### D3. Resource Usage
- [ ] Memory usage stable (no unbounded growth)
- [ ] CPU usage reasonable at idle
- [ ] No resource leaks on repeated state transitions

**Partition D Findings:**

| ID | Severity | Section | Description | Expected | Status |
|----|----------|---------|-------------|----------|--------|
| | | | | | |

---

## Consolidation

Run this section AFTER all partitions are complete.

### Merged Findings

| ID | Severity | Section | Description | Expected | Status |
|----|----------|---------|-------------|----------|--------|
| | | | | | |

### Cross-Partition Issues

Issues that span multiple partitions (e.g., a layout bug that also affects performance):

| IDs | Partitions | Description | Root Cause |
|-----|-----------|-------------|------------|
| | | | |

### Assessment

**Overall:** {PASS / CONDITIONAL PASS / FAIL}

| Partition | Result | Blocking | Non-Blocking |
|-----------|--------|----------|--------------|
| A: Visual QA | | | |
| B: Interaction | | | |
| C: Content | | | |
| D: Performance | | | |

**Blocking issues must be resolved before release.**
