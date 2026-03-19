# Specification Quality Rubric

**Version:** 1.0
**Purpose:** Standardized grading system for all SPEC-\*.md files

---

## 10-Dimension Rubric (0-2 each, 20 max)

| #   | Dimension                      | 0 (Missing)                      | 1 (Incomplete)                                     | 2 (Complete)                                                                |
| --- | ------------------------------ | -------------------------------- | -------------------------------------------------- | --------------------------------------------------------------------------- |
| D1  | **User Story**                 | None                             | Missing parts (As/I want/So that) or generic actor | Full 3-part with specific actor                                             |
| D2  | **Context / Motivation**       | None                             | Brief overview only (1-2 sentences)                | Problem statement + current state + why this matters                        |
| D3  | **Numbered FRs**               | Inline prose or bullet list      | Numbered but sparse description                    | FR-N format with per-FR description and scope                               |
| D4  | **NFRs with Targets**          | None                             | Stated without measurable numbers                  | Measurable targets (e.g., "<50ms p95", ">=90% recall")                      |
| D5  | **Acceptance Criteria**        | None or vague ("it should work") | Present but unnumbered or non-verifiable           | Numbered AC-N, each independently verifiable                                |
| D6  | **Gherkin Scenarios**          | None                             | Generic/placeholder data or pseudo-Gherkin         | Realistic domain data in proper Given/When/Then format                      |
| D7  | **Test Plan**                  | None                             | "~N tests" only                                    | File names, per-category counts, layer split (unit/integration/E2E)         |
| D8  | **API / Data Contract**        | Missing (when applicable)        | Partial (endpoint listed but no shapes)            | Full: endpoint, request/response shapes, error codes, type definitions      |
| D9  | **Dependencies**               | None                             | Named only ("requires Redis")                      | Spec IDs or module paths with relationship type (blocks, extends, consumes) |
| D10 | **Design / Technical Section** | None                             | Brief notes ("use existing pattern")               | Interface signatures, file paths, approach description, key decisions       |

### Scoring Rules

- **N/A dimensions:** If a dimension genuinely doesn't apply, score it 2 and mark "N/A". The rubric measures completeness relative to what the spec _should_ contain.
- **Partial credit:** A dimension earns 1 if the content exists but is incomplete. Err on the side of 1 over 0.
- **Gherkin (D6):** Inline Gherkin in the spec OR a referenced `.feature` file both count.

---

## Grade Thresholds

| Grade | Score Range | Interpretation                                                                 |
| ----- | ----------- | ------------------------------------------------------------------------------ |
| **A** | 17-20       | Exemplary — zero clarification needed, developer can implement from spec alone |
| **B** | 13-16       | Adequate — 1-2 minor clarifications expected, solid foundation                 |
| **C** | 9-12        | Needs Work — developer will guess on multiple points, missing key sections     |
| **D** | 5-8         | Deficient — significant rework needed before development                       |
| **F** | 0-4         | Inadequate — placeholder or stub, not a specification                          |

---

## Review Tiers & Adjusted Minimums

| Tier         | Criteria                                               | Review Protocol                                                   | Minimum Grade |
| ------------ | ------------------------------------------------------ | ----------------------------------------------------------------- | ------------- |
| **Minimal**  | P2 + Size S + infra/deploy/docs                        | PD/PM self-review only                                               | C (9+)        |
| **Standard** | P1, or Size M, or has API/data model changes           | Architect quick-check (15 min) + QE test data (15 min)            | B (13+)       |
| **Full**     | P0, or Size L/XL, or security/pipeline/domain-critical | Full Architect (45 min) + QE deep review (30 min) + PD/PM validation | A (17+)       |

### Tier Assessment Rules

1. If the spec is **P0** -> Full tier (regardless of size)
2. If the spec touches **security** or **critical pipeline** -> Full tier
3. If the spec introduces **new API endpoints** or **data model changes** -> at least Standard tier
4. If the spec is **infrastructure/deploy/docs only** and **P2** and **Size S** -> Minimal tier
5. Default -> Standard tier (when in doubt, review more, not less)

---

## Tier-Specific Templates

### Minimal Tier Template (P2, Size S, infra/deploy/docs)

```markdown
# SPEC-{ID}: {Title}

**Status:** {Planning | In Progress | Complete}
**Sprint:** {N}
**Priority:** P2
**Review Tier:** Minimal

## Summary

{1-3 sentences describing what and why}

## Requirements

- FR-1: {Primary requirement}
- FR-2: {Secondary requirement, if any}

## Acceptance Criteria

- AC-1: {Verifiable outcome}
- AC-2: {Verifiable outcome}

## Test Plan

{Brief — e.g., "Manual verification" or "~5 unit tests"}
```

### Standard Tier Template (P1, Size M, or API/data model changes)

```markdown
# SPEC-{ID}: {Title}

**Status:** {Planning | In Progress | Complete}
**Sprint:** {N}
**Priority:** P1
**Review Tier:** Standard
**Dependencies:** {Spec IDs or "None"}

## Summary

{1-3 sentences}

## Motivation

{Problem statement + current state + why}

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

- AC-1: {Verifiable, independently testable}
- AC-2: {Verifiable}

## Design

{Key interfaces, file paths, approach.}

## Test Plan

| Layer       | Count | Files                  |
| ----------- | ----- | ---------------------- |
| Unit        | ~N    | `tests/unit/{module}/` |
| Integration | ~N    | `tests/integration/`   |
```

### Full Tier Template (P0, Size L/XL, security/pipeline/domain-critical)

```markdown
# SPEC-{ID}: {Title}

**Status:** {Planning | In Progress | Complete}
**Sprint:** {N}
**Priority:** P0
**Review Tier:** Full
**Dependencies:** {Spec IDs with relationship type}

## Summary

{1-3 sentences}

## Motivation

{Problem statement + current state + why this matters + risk if not addressed}

## User Story

As a {specific actor}, I want to {capability} so that {business value}.

## Context & Background

{Technical context, architecture decisions, prior art}

## Requirements

### FR-1: {Title}

**Priority:** P0
{Detailed description with sub-requirements}

### FR-2: {Title}

{...}

## Non-Functional Requirements

### NFR-1: {Category (Performance/Reliability/Security)}

- **Target:** {Measurable, e.g., "<50ms p95"}
- **Rationale:** {Why this target}

## Acceptance Criteria

- AC-1: {Independently verifiable}
- AC-2: {Independently verifiable}

## Gherkin Scenarios

\`\`\`gherkin
Feature: {Feature name}
Scenario: {Happy path with realistic data}
Given {precondition}
When {action}
Then {verifiable outcome}

Scenario: {Error/boundary case}
Given {edge condition}
When {action}
Then {expected behavior}
\`\`\`

## Design

{Architecture diagram, interface signatures, module structure, key decisions}

### API / Data Contract

{Endpoint, request/response type definitions, error codes}

### Files to Modify

| File              | Change Type   | Notes    |
| ----------------- | ------------- | -------- |
| `src/{module}/**` | New interface | Per FR-1 |

## Test Plan

| Layer       | Count | Files                      | Coverage           |
| ----------- | ----- | -------------------------- | ------------------ |
| Unit        | ~N    | `tests/unit/{module}/`     | {module} functions |
| Integration | ~N    | `tests/integration/`       | API routes         |
| Gherkin     | ~N    | `tests/features/{domain}/` | Acceptance         |
| E2E         | ~N    | E2E tests                  | User journey       |

## Dependencies

| Spec ID  | Relationship | Notes               |
| -------- | ------------ | ------------------- |
| SPEC-XXX | Blocks       | Must complete first |
```

---

## Developer Handoff Template

Appended to any spec after collaborative review:

```markdown
## Developer Handoff

### Review Tier: {Minimal | Standard | Full}

### Reviewed By: {Architect (date), QE (date) | PD/PM self-review only}

### Key Implementation Points

1. {Most critical FR — drives the architecture}
2. {Secondary FRs in dependency order}
3. {Specific constraint or gotcha}

### Files to Modify

| File              | Change Type   | Notes    |
| ----------------- | ------------- | -------- |
| `src/{module}/**` | New interface | Per FR-2 |

### Existing Patterns to Follow

- Follow pattern in `{reference-file}` for {pattern-name}

### Out of Scope (Explicit)

- {Adjacent concern deferred to another spec}
```

---

## Collaborative Review Protocol

### Step 1: PD/PM Writes Draft Spec

- Use tier-appropriate template above
- Tag `Review Tier: {Minimal|Standard|Full}` in metadata

### Step 2: Architect Technical Review (Standard + Full tiers)

Annotates with:

- `> [ARCH-Q]` questions for PD/PM to resolve
- `> [ARCH-NOTE]` informational notes for developer
- API contract shapes, cross-module impact, NFR targets

### Step 3: QE Testability Review (Standard + Full tiers)

Annotates with:

- `> [QE-Q]` testability concerns
- `> [QE-DATA]` Gherkin scenarios with realistic domain data
- Boundary cases, error paths, test plan with file names

### Step 4: PD/PM Validates + Produces Handoff

- Resolves all annotations
- Appends Developer Handoff section
- Final grade check against tier minimum

### Annotation Conventions

| Tag             | Owner     | Meaning                                |
| --------------- | --------- | -------------------------------------- |
| `> [ARCH-Q]`    | Architect | Question needing PD/PM clarification   |
| `> [QE-Q]`      | QE        | Testability concern                    |
| `> [ARCH-NOTE]` | Architect | Informational context for developer    |
| `> [QE-DATA]`   | QE        | Test data / Gherkin scenario injection |
