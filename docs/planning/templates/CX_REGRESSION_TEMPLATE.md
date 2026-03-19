---
type: cx-regression
status: template
sprint: "{SPRINT_ID}"
profile: "{PROJECT_PROFILE}"
---

# CX Regression Checklist

**Auditor:** CX Designer persona
**Date:** {DATE}
**Scope:** Full CX regression — all user-facing interaction surfaces
**Prerequisite:** Blueprint phase complete. Fill placeholders after Blueprint produces the interaction inventory.

---

## How to Use This Template

1. Complete the Blueprint phase for your project
2. Replace all `{PLACEHOLDER}` sections with your project-specific surfaces, transitions, and contracts
3. Run through each section sequentially, marking pass/fail/skip
4. Record findings inline with severity (P0–P3)
5. Consolidate findings into the summary at the end

**Marking convention:** `[x]` pass, `[ ]` fail (add finding), `[-]` skip with reason

---

## 1. Interaction Surface Audit

Verify every user-facing surface renders correctly and responds to input as specified.

{INTERACTION_SURFACES}

<!-- Replace with your project's surfaces. Example format:
### Surface: {Name}
- [ ] Renders without visual artifacts
- [ ] All interactive elements respond to input
- [ ] Visual hierarchy matches design intent
- [ ] Content is legible at all supported sizes
- [ ] No orphaned or clipped elements
-->

---

## 2. State Transition Verification

Verify all key state changes produce correct visual and behavioral updates.

{KEY_STATE_TRANSITIONS}

<!-- Replace with your project's transitions. Example format:
### Transition: {From State} → {To State}
- [ ] Trigger condition activates correctly
- [ ] Visual feedback during transition
- [ ] Final state renders correctly
- [ ] No intermediate flicker or ghost states
- [ ] Reverse transition (if applicable) works
-->

---

## 3. Responsive / Adaptive Checks

Verify the interface adapts correctly across supported form factors.

{FORM_FACTOR_MATRIX}

<!-- Replace with your project's form factors. Example format:
### Form Factor: {Size/Device/Context}
- [ ] Layout adapts without overflow
- [ ] Content remains accessible
- [ ] Interactive elements remain reachable
- [ ] No content truncation without indication
- [ ] Graceful degradation at minimum supported size
-->

---

## 4. Animation / Motion Audit (Optional)

Skip this section if your project has no animation or motion elements.

{MOTION_INVENTORY}

<!-- Replace with your project's animations. Example format:
### Animation: {Name}
- [ ] Starts on correct trigger
- [ ] Frame rate is smooth (no jank or stutter)
- [ ] Duration matches specification
- [ ] Completes cleanly (no stuck frames)
- [ ] Respects reduced-motion preferences (if applicable)
-->

---

## 5. Content Variety Checks (Optional)

Skip this section if your project has no dynamic or variable-length content.

{DYNAMIC_CONTENT_CHECKS}

<!-- Replace with your project's dynamic content surfaces. Example format:
### Content Surface: {Name}
- [ ] Empty state renders correctly
- [ ] Single item renders correctly
- [ ] Typical content (3–10 items) renders correctly
- [ ] Maximum expected content renders without breakage
- [ ] Overflow handling (scroll, truncation, pagination) works
- [ ] Special characters and long strings handled
-->

---

## 6. Performance Baselines

Verify interaction performance meets project contracts.

{PERFORMANCE_CONTRACTS}

<!-- Replace with your project's performance contracts. Example format:
### Metric: {Name}
- **Contract:** {threshold, e.g., < 100ms}
- **Method:** {how to measure}
- [ ] Meets contract under normal conditions
- [ ] Meets contract under stress conditions (if applicable)
-->

---

## 7. End-to-End User Journey

Walk the primary user journey from start to finish without interruption.

{PRIMARY_USER_JOURNEY}

<!-- Replace with your project's primary journey. Example format:
### Journey: {Name}
**Steps:**
1. {Step 1} — [ ] Pass
2. {Step 2} — [ ] Pass
3. {Step 3} — [ ] Pass
...

- [ ] Journey completes without error
- [ ] Each step transitions cleanly to the next
- [ ] No dead ends or confusing states
- [ ] Final state matches user expectation
-->

---

## 8. Error / Edge Case Surfaces

Verify error states and edge cases are handled gracefully.

{ERROR_STATES}

<!-- Replace with your project's error surfaces. Example format:
### Error Surface: {Name}
- [ ] Error state is visually distinct from success
- [ ] Error message is actionable (tells user what to do)
- [ ] Recovery path exists and works
- [ ] No raw technical output exposed to user
- [ ] Repeated errors do not accumulate or corrupt state
-->

---

## Findings Summary

| # | Section | Severity | Description | Status |
|---|---------|----------|-------------|--------|
| 1 | | | | |

**Overall Assessment:** {PASS / CONDITIONAL PASS / FAIL}

**Blocking Issues:** {count}
**Non-Blocking Issues:** {count}

---

## Adopter Instructions

After completing your Blueprint phase:

1. **Interaction surfaces** — list every screen, view, panel, page, or output the user sees
2. **State transitions** — list every state change that alters what the user sees or can do
3. **Form factors** — list every size, device, or context you support (terminal widths, screen sizes, viewports)
4. **Animations** — list every motion element (or mark section as skipped)
5. **Dynamic content** — list every surface that shows variable-length or user-generated content
6. **Performance contracts** — list every timing or resource budget from your specs
7. **User journey** — write out the primary happy-path journey step by step
8. **Error states** — list every error condition the user might encounter

Run this checklist at the end of every sprint that touches user-facing code. Compare findings against previous runs to catch regressions.
