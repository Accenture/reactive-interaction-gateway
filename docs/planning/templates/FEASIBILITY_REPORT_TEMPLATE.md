---
type: template
name: Pre-Build Feasibility Report
phase: Specification
produces: Semantic agent feasibility report
---

# Pre-Build Feasibility Report: SPEC-{ID}

**Produced by:** Semantic Agent (spec finalization, pre-Build)
**Consumed by:** Developer (Build start — flag structural issues before implementation)
**Date:** {YYYY-MM-DD}

---

## Design Section Alignment

| Proposed Module | Exists? | Notes |
|----------------|---------|-------|
| {module from spec Design section} | Yes / No (new) / Partial | {any structural concerns} |

## Import Chain Analysis

- **Circular dependency risk:** {None detected / Risk: {description}}
- **Transitive dependency count:** {N modules affected by proposed changes}
- **Breaking changes:** {None / {description of what breaks}}

## Duplicate Functionality Check

| Proposed Functionality | Existing Implementation | Overlap |
|-----------------------|------------------------|---------|
| {what spec proposes} | {existing module/function, if any} | {None / Partial / Full — recommend reuse} |

## Codebase Assumptions

| Spec Assumption | Verified? | Evidence |
|----------------|-----------|----------|
| {assumption from spec Design section} | Yes / No / Partially | {file:line or "not found"} |

## Recommendation

{Proceed / Revise spec Design section — {specific changes needed}}

---

_This is a 10-15 minute check, not a deep audit. The goal is to catch obvious mismatches before Build._
