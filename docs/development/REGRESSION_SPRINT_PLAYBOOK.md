# Regression Sprint Playbook

**Purpose:** Official process for fix/regression sprints. Replaces ad-hoc bug-fix cycles with a structured, multi-pass, agent-parallelized approach.

**Origin:** Established from real regression sprint data (30 sprints of production use). Validated approach: 6% pass rate to 81% in a single structured session.

**Owner:** QE persona (with Architect verification)

---

## When to Use

- After a feature sprint when E2E test pass rate drops below 80%
- After significant UI refactors that may break test selectors
- Before release candidates
- When user reports multiple regressions from a single build

---

## Process Overview

```
Pass 1: Baseline → Diagnose → Document
Pass 2: Fix → Verify → Document
Pass 3: Deep investigation → Edge cases → Document
Pass N: Repeat until green
Final: Baseline update → Commit
```

---

## Pass 1: Baseline & Diagnosis

### 1.1 Pre-flight Checks
- [ ] Required ports are free
- [ ] Dependencies are current
- [ ] No uncommitted changes that could affect test behavior
- [ ] External services (Docker, databases) are not conflicting

### 1.2 Run Baseline
```bash
npm test  # or project-specific test command
```

Record: total tests, passed, failed, skipped.

### 1.3 Categorize Failures

Use **parallel agents** for diagnosis:
- **Architect agent**: Read failing test code + app source, identify root causes
- **QE agent**: Run dev server manually, check for runtime errors
- **Explore agent**: Search for recent changes that might have caused breakage

Categorize each failure into:

| Category | Description | Example |
|----------|-------------|---------|
| **Selector drift** | UI changed, test selectors don't match | Button text changed, new dialog step |
| **API mock gap** | Mock doesn't intercept correct route | Proxy vs direct URL |
| **Race condition** | Timing/async issue | Click before element rendered |
| **Real bug** | App code is actually broken | Logic error, missing import |
| **Baseline drift** | Visual regression baselines outdated | Screenshot pixel diff |
| **Env issue** | Port conflict, missing deps, stale cache | Docker on expected port |

### 1.4 Write Pass 1 Findings
Write to `docs/planning/retrospectives/REGRESSION-SPRINT-{N}-PASS1.md`:
- Baseline numbers
- Root causes with severity (P0/P1/P2/P3)
- Affected test count per root cause
- Fix priority order

---

## Pass 2+: Fix & Verify

### 2.1 Agent Separation (MANDATORY)

**Never have one agent both diagnose AND fix.** Use this pattern:

| Agent | Role | Tools |
|-------|------|-------|
| **QE agent** | Write fixes, update selectors, add waits | Edit, Write, Bash |
| **Architect agent** | Review QE fixes against source components | Read, Grep, Glob |
| **Explore agent** | Find related code, check for similar patterns | Read, Grep, Glob |

**Workflow per fix:**
1. QE agent writes the fix
2. Architect agent reviews fix against actual component source
3. Architect reports PASS/FAIL with specific issues
4. If FAIL: QE agent revises
5. If PASS: proceed to next fix

### 2.2 Fix Priority Order
1. **P0 — Systemic blockers** (fix first, unblocks most tests)
2. **P1 — Auth/API issues** (unblocks remaining functional tests)
3. **P2 — Env/config issues** (port conflicts, missing setup)
4. **P3 — Visual baselines** (update LAST, after all UI fixes stabilize)

### 2.3 Run Verification
```bash
npm test
```
Compare against previous pass. Document delta.

### 2.4 Write Pass N Findings
Update or create `docs/planning/retrospectives/REGRESSION-SPRINT-{N}-PASS{M}.md`:
- New pass results
- Fixes applied
- Remaining failures
- New issues discovered

---

## Pass 3+: Deep Investigation

For tests that survive multiple fix passes:

### 3.1 Root Cause Deep Dive
- Run individual failing test with debug flags
- Use interactive browser debugging tools
- Check for:
  - Framework hydration timing (SSR → client takeover)
  - Storage initialization race conditions
  - Streaming response timing
  - Re-render during test framework actionability checks

### 3.2 Targeted Fixes
- Add explicit waits for hydration
- Use framework-specific click approaches for complex UI states
- Add readiness checks for async storage
- Respect framework-specific networking behavior in test configuration

---

## Final Pass: Baseline & Ship

### 4.1 Update Visual Regression Baselines
Update baselines ONLY after all functional fixes are stable.

### 4.2 Run Full Suite (Confirmation)
Target: 100% pass rate on mocked tests. Real-API tests may have legitimate flakiness.

### 4.3 Commit & Document
1. Commit all test fixes
2. Update delivery plan with sprint results
3. Write final retro
4. Update test count in CLAUDE.md

---

## Parallelization Guide

### What to parallelize
- Multiple independent test file fixes (use worktree agents if touching different files)
- Diagnosis + documentation (one agent investigates, another documents)
- Test run + fix preparation (queue next fixes while tests run)

### Test Runner Configuration
- Limit parallel workers to avoid overwhelming dev servers (2-3 workers typical maximum)
- If tests are flaky on navigation, reduce workers first before investigating test code
- CI environments should use fewer workers than local dev

### What NOT to parallelize
- Fixes to the same file (merge conflicts)
- Test runs (single test runner instance)
- Baseline updates (must happen after ALL functional fixes)

---

## Andon Principle (MANDATORY)

**When any agent or tool encounters a failure — STOP THE LINE.** Do not move on, do not take the shortest path that skips the broken item. Fix the root cause first, then continue.

This applies to ALL processes, not just regression sprints:
- Test runner won't start → diagnose and fix before running any tests
- Dev server dropping connections → reduce workers, investigate, don't just re-run
- A fix doesn't work → understand WHY before trying another fix
- Tool call fails → investigate the failure, don't retry blindly
- Infra is broken → that's the top priority, not the feature work

**Origin:** Lean manufacturing principle (Toyota Production System / jidoka). Stopping to fix is faster than pushing through with broken tooling.

---

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Fix tests without reading source component | Always cross-reference the actual UI component |
| Update baselines before fixing functional issues | Fix functional first, baselines last |
| Retry flaky tests hoping they pass | Investigate root cause (timing, race condition) |
| Fix in main session without agent separation | Use QE + Architect agent pattern |
| Assume a fix works without re-running | Always verify with full suite re-run |
| Skip documentation between passes | Write findings doc after every pass |

---

## Metrics to Track

| Metric | Where |
|--------|-------|
| Tests passed/failed per pass | Findings docs |
| Root causes identified | Findings docs |
| Passes needed to reach green | Retro |
| Regressions introduced by fixes | Retro (should be 0) |
