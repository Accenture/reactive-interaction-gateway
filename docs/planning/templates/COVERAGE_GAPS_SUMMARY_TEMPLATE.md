---
type: template
name: Coverage Gaps Summary
phase: Sprint Close
produces: QE coverage gaps summary for Product sprint planning
---

# Coverage Gaps Summary — Sprint {N}

**Produced by:** QE Agent (sprint close audit)
**Consumed by:** Product Agent (sprint planning — informs spec priorities and review tier decisions)
**Date:** {YYYY-MM-DD}

---

## Critical Gaps (P0 — affects sprint planning)

Modules or components with zero or critically insufficient test coverage that represent risk to the system.

| Module / Component | Gap Description | Risk | Recommended Action |
|--------------------|----------------|------|-------------------|
| {module path} | {what's missing} | {consequence if untested} | {add unit tests / add integration tests / promote from skip registry} |

## Moderate Gaps (P1 — inform spec review tier)

Areas with partial coverage that should receive attention when touched by upcoming work.

| Module / Component | Gap Description | Current Coverage | Recommended Action |
|--------------------|----------------|-----------------|-------------------|
| {module path} | {what's thin} | {approximate coverage} | {upgrade to Standard tier review if spec touches this / add boundary tests} |

## Observations (P2 — track over time)

Coverage patterns or trends worth monitoring but not actionable this sprint.

- {observation with evidence}

## Untested Risk Areas

Modules or features identified as high-risk but lacking adequate test coverage. These should be considered when prioritizing specs for the next sprint.

| Risk Area | Why High Risk | Current Test State | Sprint Recommendation |
|-----------|--------------|-------------------|----------------------|
| {area} | {reason} | {none / minimal / partial} | {add to sprint backlog / flag in spec review / defer with rationale} |

---

_This summary is overwritten each sprint close. Historical coverage trends are tracked in IE Process Memory._
