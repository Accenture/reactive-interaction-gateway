---
type: cx-smoke-test
status: template
sprint: "{SPRINT_ID}"
profile: "{PROJECT_PROFILE}"
duration: "~5 minutes"
---

# CX Smoke Test Checklist

**Tester:** {TESTER}
**Date:** {DATE}
**Build:** {BUILD_REF}
**Duration target:** ~5 minutes

---

## Purpose

Fast verification that the build is not broken in ways visible to users. This is NOT a full regression — it covers only the critical path. Run this after every build, before deeper testing.

**Pass criteria:** All items pass. Any failure = stop and investigate before proceeding.

---

## 1. Build Clean

Verify the project builds without errors.

- [ ] Build command completes with exit code 0
- [ ] No warnings that indicate runtime issues
- [ ] Build output artifact exists and is valid

**Build command:** `{BUILD_COMMAND}`

---

## 2. Launch Check

Verify the application starts and reaches a usable state.

- [ ] Application launches without crash
- [ ] Initial view renders within {LAUNCH_TIME_CONTRACT}
- [ ] No error output on stderr during startup
- [ ] Application responds to input after launch

**Launch command:** `{LAUNCH_COMMAND}`

---

## 3. Critical Path

Walk the single most important user journey. This should be the one thing that absolutely must work.

{CRITICAL_PATH}

<!-- Replace with your critical path. Example format:
1. {Action} — [ ] Expected result observed
2. {Action} — [ ] Expected result observed
3. {Action} — [ ] Expected result observed
-->

---

## 4. Render Spot Check

Quick visual inspection of the most important surfaces.

- [ ] Primary view renders without visual artifacts
- [ ] Text is legible and not clipped
- [ ] Colors/styling appear correct (not raw/unstyled)
- [ ] No placeholder or debug text visible

---

## 5. Performance Spot Check

Quick verification that performance is in the right ballpark.

- [ ] Application feels responsive to input (no perceptible lag)
- [ ] No obvious memory issues (no freeze, no runaway process)
- [ ] Application exits cleanly on quit command

---

## Result

**Outcome:** {PASS / FAIL}

If FAIL, describe the failure:

**Failed item:** {section.item}
**Observed:** {what happened}
**Expected:** {what should have happened}
**Severity:** {blocks all testing / blocks specific area}
