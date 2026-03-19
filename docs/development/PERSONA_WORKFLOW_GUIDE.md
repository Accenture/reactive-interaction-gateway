# Persona Workflow Guide

## Overview

This project uses **12 personas** to drive the development workflow. Each persona has a defined role, scope, and handoff protocol. Work follows a **phase-ordered workflow** with mandatory challenge gates between design phases.

---

## Personas

| Persona | Role | Skill Binding |
| --- | --- | --- |
| Product Designer / Product Manager | Domain-agnostic facilitator (discovery), spec creator & quality gate enforcer (build) | `/product` |
| Architect | System designer, service boundaries, event architecture | `/architect` |
| Frontend Engineer | UI specialist, component architecture | `/frontend` |
| Backend Engineer | Service developer, API implementation | `/backend` |
| Quality Engineer | Test pyramid, contract tests, coverage enforcement | `/qe` |
| CX Designer | Visual QA, accessibility, UX flow | `/cx` |
| DevOps | Infrastructure, CI/CD, deployment | `/devops` |
| Contrarian | Assumption challenger, ICN protocol | `/contrarian` |
| Contrarian (Editorial) | Plain-language assumption challenger for broad audiences | `/contrarian-editorial` |
| Industrial Engineer | Continuous improvement, waste detection, retro tracking | `/ie` |
| Semantic Reviewer | Spec-code alignment, drift detection | `/semantic` |
| Integration & External Systems | Event schemas, messaging contracts, legacy analysis, ACL design | `/integration` |
| Coherence Architect | Document coherence, narrative consistency, thread integrity | `/strategy` |

---

## Phase-Ordered Workflow

All work follows a strictly sequential phase progression. See `.claude/agents/_patterns.md` for the authoritative definition.

```
Vision → [Challenge] → Concept → [Challenge] → Blueprint → [Challenge] → Specification → Build → Verify
```

Each `[Challenge]` is a mandatory Contrarian challenge session that must complete before the next phase begins.

### Sequential Handoff Workflow (Build Phase)

```
Product → Architect → CX Designer → Frontend/Backend → QE → Semantic
```

### Spec-First Workflow Lifecycle

1. **Draft** — Product Designer / Product Manager creates SPEC-*.md
2. **Architect Review** — Annotates with `[ARCH-Q]`, adds API/event contracts
3. **CX Review** — Annotates with visual acceptance criteria (UI specs)
4. **Integration Review** — Annotates with event schema requirements (event specs)
5. **Semantic Review** — Validates spec completeness
6. **Approved** — All annotations resolved
7. **Development** — Frontend/Backend implement per spec
8. **Test** — QE writes and runs tests per acceptance criteria
9. **Done** — All quality gates pass

---

## Mandatory Challenge Gates

After every Vision, Concept, and Blueprint session, a Contrarian challenge session MUST occur. This is a hard gate — the workflow cannot advance without it.

### Rules

1. Contrarian is spawned automatically after each Vision/Concept/Blueprint session
2. Challenges are presented **one at a time** with options and a recommendation
3. User decides each challenge before the next is presented
4. Minimum output: one incongruent representation + one unasked question (Light of Ignorance)
5. If any agent notices the lead attempting to skip → **halt and flag**

See `.claude/agents/contrarian.md` Rule 12 for enforcement details.

---

## Decision Presentation Protocol

All agents follow the Decision Presentation Protocol when presenting choices to the user (see `.claude/agents/_patterns.md`):

1. One decision at a time — never batch
2. 2–3 clear options with pros/cons
3. Recommendation with rationale
4. Wait for user decision before proceeding

---

## Collaboration Triggers

| Work Type | Lead | Co-spawn |
| --- | --- | --- |
| L/XL feature specs | Product | Architect + QE |
| UI-facing specs | Product | CX Designer |
| Event-driven specs | Product | Integration + Architect |
| Legacy integration specs | Product | Integration + Architect |
| ACL design | Architect | Integration |
| Sprint planning / sprint close | Product | Industrial Engineer (process health) |
| Cross-service changes | Backend | Architect |
| Contract tests | QE | Integration |
| Vision/Concept docs | Product | Contrarian (mandatory post-session) |
| Blueprint decisions | Architect | Contrarian (mandatory post-session) |
| Cross-domain hard problem | Domain lead | Decisive Point assembly (3-5 agents) |
| Systemic quality degradation | QE or Semantic | Elastic Defense coalition |
| Unknown terrain exploration | Any | Reconnaissance in Force (2-3 agents) |

---

## Skill Binding Lifecycle

Skills are activated in two gates, enforcing a clean separation between tech-agnostic discovery and tech-specific implementation.

### Gate 1 (Pre-Blueprint) — Tech-Agnostic Skills

- Product Designer / Product Manager
- Architect
- Contrarian
- Contrarian (Editorial)
- Industrial Engineer
- Semantic
- Coherence Architect

**Rule:** During Vision, Concept, and Blueprint phases, no agent may reference specific frameworks, languages, or libraries. Technology decisions are outputs of Blueprint, not inputs.

**Rationale:** Premature technology commitment constrains the solution space before the problem is fully understood. Tech-agnostic discovery ensures the team solves the right problem before choosing tools.

### Gate 2 (Post-Blueprint) — Tech-Specific Skills

- Frontend Engineer
- Backend Engineer
- QE
- CX Designer
- DevOps
- Integration & External Systems

**Rule:** Activated only after Blueprint artifacts are committed and challenged.

**Rationale:** Tech-specific agents need stable architectural decisions (from Blueprint) to make informed implementation choices. Activating them earlier wastes effort on decisions that may change.

### Tech Convention Loading

After Blueprint phase completes, all Post-Blueprint agents read:
1. Project `CLAUDE.md` — technology stack and project conventions
2. Any convention files referenced in the tech stack section
3. Relevant Blueprint/ADR documents for architectural context

This ensures implementation agents are aligned with both the architecture and the project's specific technology choices.

---

## Branch Naming Convention

```
<type>/<spec-id>-<short-description>

Types: feature, fix, docs
Examples:
  feature/SPEC-UI-001-wizard-scaffold
  fix/SPEC-BFF-001-validation-bypass
  docs/sprint-1-retro
```
