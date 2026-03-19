# Getting Started — From Blueprint to Running Code

This guide walks you through the complete DDE workflow: creating your solution blueprint, cutting it into a delivery plan and initial specifications, then executing your first sprint.

---

## Before You Begin: Session Mode

At the start of every session, determine your session mode:

> **Are you improving the kit itself, or building a new project with it?**

| Mode | What it means | Artifacts go to |
| ---- | ------------- | --------------- |
| **Kit Improvement** | Changing agents, templates, workflows, docs that ship with the kit | `.kit-dev/` |
| **Project Build** | Using the kit to build a real product | `docs/planning/` |

This decision determines where delivery plans, retrospectives, and session logs are written. See `CLAUDE.md` for full details on session mode behavior.

---

## Phase 1: Solution Blueprint (Architect persona)

The blueprint is the architectural foundation. It defines the system context, technology choices, service boundaries, data models, and quality targets. Everything downstream flows from this document.

### Steps

1. **Start with the template:** Copy `docs/architecture/SOLUTION_BLUEPRINT_TEMPLATE.md`
2. **Fill in sections 1-3 first:** Executive Summary, System Context, Architecture Overview
3. **Make technology decisions:** Fill in the Tech Stack table with rationale for each choice
4. **Define service boundaries:** Section 4 — what services exist, what each owns
5. **Define data architecture:** Section 5 — what stores, what models, how data flows
6. **Sketch API contracts:** Section 6 — key endpoints, request/response shapes
7. **Define security posture:** Section 8 — auth, authz, data protection
8. **Define quality targets:** Section 11 — test pyramid, coverage targets, quality gates

### Key Decisions to Document as ADRs

For each significant technology choice, create an ADR in `docs/architecture/ADR-NNN-title.md`:

- **Database selection** — Why this DB over alternatives?
- **Framework selection** — Why this framework?
- **Event architecture** — Synchronous vs event-driven? Why?
- **Auth strategy** — JWT vs sessions vs OAuth? Why?

### Output

- `docs/architecture/SOLUTION_BLUEPRINT.md` — Complete blueprint
- `docs/architecture/ADR-001-*.md` through `ADR-00N-*.md` — Key decisions
- Updated `CLAUDE.md` — Technology stack section filled in

### Time Budget

| Blueprint Size                      | Typical Duration | When                         |
| ----------------------------------- | ---------------- | ---------------------------- |
| Small (monolith, 1-2 services)      | 1-2 hours        | Solo architect               |
| Medium (3-5 services, event-driven) | 3-5 hours        | Architect + Product review   |
| Large (microservices, multi-team)   | 1-2 days         | Architect + Product + DevOps |

---

## Phase 2: Delivery Plan (Product Designer / Product Manager persona)

The delivery plan translates the blueprint into sequenced work. You decompose the system into features, prioritize them, and organize them into sprints.

### Steps

1. **Identify features from the blueprint:** Each service boundary, API endpoint, data model, and integration point suggests one or more features
2. **Size each feature:** S (1-2 days), M (3-5 days), L (1-2 weeks), XL (2+ weeks)
3. **Prioritize:** P0 (must have for MVP), P1 (important), P2 (nice to have)
4. **Identify dependencies:** Which features block others?
5. **Sequence into sprints:** Group features into 1-2 week sprints based on dependencies

### Decomposition Heuristic

For each blueprint section, ask:

- **Section 4 (Services):** Each module = at least one spec
- **Section 5 (Data):** Each data model = one spec for the model + one for the access layer
- **Section 6 (APIs):** Each API endpoint = one spec (or group related endpoints)
- **Section 7 (Events):** Each event flow = one spec
- **Section 8 (Security):** Auth, authz, input validation = separate specs
- **Section 9 (Observability):** Metrics, logging, tracing = one combined spec or separate per concern

### Sprint Structure Template

```
Sprint 0: Foundation (scaffolding, CI/CD, base infrastructure)
Sprint 1: Core Domain (primary data models, basic CRUD)
Sprint 2: Business Logic (domain rules, validation, processing)
Sprint 3: Integration (external systems, event flows)
Sprint 4: Quality (security hardening, observability, performance)
Sprint 5: Polish (UX improvements, documentation, deployment)
```

### Output

- `docs/planning/DELIVERY_PLAN.md` — Populated with sprints, backlog, dependencies
- Updated `CLAUDE.md` — Sprint status section

---

## Phase 3: Initial Specifications (Product Designer / Product Manager persona)

Write specs for Sprint 1 before writing any code. Use the tiered templates from `docs/specs/SPEC_QUALITY_RUBRIC.md`.

### Steps

1. **Pick work items for Sprint 1** from the delivery plan
2. **For each work item, create a spec:**
   - Determine review tier (Minimal/Standard/Full) based on priority and size
   - Use the corresponding template from `SPEC_QUALITY_RUBRIC.md`
   - Fill in: Summary, Motivation, User Story, Requirements, NFRs, Acceptance Criteria
3. **Run collaborative review** if Standard or Full tier:
   - Architect reviews: API contracts, cross-module impact, NFR targets
   - QE reviews: Gherkin scenarios, boundary cases, test plan
4. **Register specs** in `docs/specs/SPEC_REGISTRY.md`
5. **Commit all specs** before starting implementation

### Spec Naming Convention

```
SPEC-{CATEGORY}-{NUMBER}-descriptive-name.md

Examples:
  SPEC-AUTH-001-user-authentication.md
  SPEC-API-001-rest-endpoints.md
  SPEC-DATA-001-user-model.md
  SPEC-UI-001-dashboard-layout.md
```

### Quality Check

Before moving to development, verify:

- [ ] All Sprint 1 specs exist in `docs/specs/`
- [ ] Each spec has acceptance criteria (preferably Gherkin)
- [ ] Each spec meets its tier's minimum grade
- [ ] Dependencies between specs are documented
- [ ] SPEC_REGISTRY.md is up to date

---

## Phase 4: First Sprint Development

### Session Lifecycle

Every Claude Code session follows this cycle:

```
1. Review CLAUDE.md + relevant spec(s)
2. Enter plan mode for non-trivial work
3. Cut feature branch from dev
4. Implement (persona-appropriate work)
5. Run tests + type check
6. Update CLAUDE.md stats
7. Commit and merge to dev
```

### Development Flow Per Feature

```
Product Designer / Product Manager         Architect              Developer            QE
      |                     |                     |                  |
  Write Spec  -------->  Review Spec  ------->  Implement  ------> Test
      |                     |                     |                  |
  (SPEC-*.md)          (> [ARCH-Q])           (src/**)          (tests/**)
      |                     |                     |                  |
      |                  ADR if needed         Unit tests         Integration
      |                     |                     |                  |
      +------ Validate <----+-------- Verify <----+------- Report --+
```

### Parallel Execution (Agent Teams)

For independent features, spawn parallel agent teams:

1. Identify features with zero file overlap
2. Spawn 2 teammates in `dontAsk` mode (spec IS the plan)
3. Each teammate reads their skill file + spec
4. Quality gate hooks run on task completion
5. Wait for both to complete before next phase

### Sprint Close

1. **Live Demo** — Walk through what was built
2. **Retrospective** — Fill in `SPRINT_RETROSPECTIVE_TEMPLATE.md`
3. **Update docs** — CLAUDE.md (stats), DELIVERY_PLAN.md (status), SPRINT_HISTORY.md
4. **Merge to main** — PR from `dev` to `main` with merge commit
5. **Deploy** — Optional; ask user

---

## Quick Reference: What Persona Does What

| Phase     | Primary Persona                   | Deliverable                      | Key Document            |
| --------- | --------------------------------- | -------------------------------- | ----------------------- |
| Blueprint | Architect                         | System architecture              | `SOLUTION_BLUEPRINT.md` |
| Plan      | Product Designer / Product Manager                  | Sprint structure                 | `DELIVERY_PLAN.md`      |
| Specs     | Product Designer / Product Manager + Architect + QE | Feature specs                    | `docs/specs/SPEC-*.md`  |
| Design    | Architect                         | API contracts, DI interfaces     | ADRs, design docs       |
| Implement | Developer (Backend/Frontend)      | Source code + unit tests         | `src/**`                |
| Test      | QE                                | Integration + E2E tests          | `tests/**`              |
| Visual QA | CX Designer                       | Design audit + visual regression | Playwright snapshots    |
| Deploy    | DevOps                            | Infrastructure + deploy scripts  | `k8s/**`, `deploy/**`   |
| Accept    | Product Designer / Product Manager                  | Validation + demo                | Retro document          |

---

## Checklist: Ready for Sprint 1?

- [ ] Solution blueprint created (at least sections 1-6)
- [ ] Key ADRs documented
- [ ] Delivery plan populated with Sprint 1 work items
- [ ] Sprint 1 specs written and reviewed
- [ ] SPEC_REGISTRY.md has all specs listed
- [ ] CLAUDE.md customized for your project
- [ ] Agent skill files customized for your tech stack
- [ ] Git repo initialized with `main` and `dev` branches
- [ ] Test framework configured
- [ ] CI/CD pipeline running (or planned for Sprint 0)

---

_This guide is part of the DDE Starter Kit. See README.md for the complete file inventory._
