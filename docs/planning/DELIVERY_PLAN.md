---
type: delivery-plan
version: 0.1.0
last_updated: "2026-03-18"
mode: project-build
cumulative_stats:
    tests: 37
    test_suites: 15
    specifications: 0
    agents: 15
active_sprint:
    number: 0
    label: 'S0'
    title: 'DDE Initialization & Codebase Scan'
    status: 'Complete'
    goal: 'Initialize DDE methodology on existing RIG codebase — Vision, Concept, Blueprint, agent skill binding'
    dependency: ""
    start_date: '2026-03-18'
planned_sprints:
    - number: 1
      title: 'Dependency Modernization & Test Baseline'
      goal: 'Upgrade Elixir/OTP, replace deprecated deps, establish test coverage baseline'
---

## Active Sprint

### Sprint 0: DDE Initialization & Codebase Scan

**Status:** Complete
**Duration:** 2026-03-18
**Goal:** Initialize DDE methodology on existing RIG codebase — Vision, Concept, Blueprint, agent skill binding

| WI | Title | Spec | Size | Status | Tests |
| --- | --- | --- | --- | --- | --- |
| 0.1 | Copy DDE starter kit structure | — | S | Done | — |
| 0.2 | Run init-project.sh with RIG config | — | S | Done | — |
| 0.3 | Create CLAUDE.md (project context) | — | M | Done | — |
| 0.4 | Create Vision document | — | M | Done | — |
| 0.5 | Create Concept document | — | M | Done | — |
| 0.6 | Create Solution Blueprint | — | L | Done | — |
| 0.7 | Customize agent skill files (9 agents) | — | L | Done | — |

**Sprint Notes:** Planning-only sprint — no code changes to RIG source. All DDE infrastructure and phase artifacts created. Existing test suite (37 files) not modified.

---

## Planned Sprints

### Sprint 1: Dependency Modernization & Test Baseline

**Status:** Planning
**Goal:** Upgrade Elixir/OTP, replace deprecated deps, establish test coverage baseline

| Priority | Item | Size | Notes |
| --- | --- | --- | --- |
| P0 | Upgrade Elixir 1.11→1.17+ / OTP 23→27 | L | ADR-001 — foundational, everything else depends on this |
| P0 | Replace Distillery with mix release | M | ADR-002 — Distillery is deprecated |
| P1 | Upgrade Joken 1.x→2.x | M | ADR-004 — JWT library unmaintained |
| P1 | Establish ExCoveralls baseline | S | Measure current coverage before changes |
| P2 | Migrate OpenCensus→OpenTelemetry | L | ADR-003 — OpenCensus EOL |

---

## Sprint History

| Sprint | Title | Status | Dates | Tests Added | Key Deliverables |
| --- | --- | --- | --- | --- | --- |
| 0 | DDE Initialization | Complete | 2026-03-18 | +0 | CLAUDE.md, Vision, Concept, Blueprint, 9 agent skill files |

---

## Backlog

### Ready (Spec Complete, Sequenced)

_No specs yet — Sprint 0 was pre-Specification phase._

### Needs Spec (Idea, Not Yet Specified)

| Priority | Idea | Notes | Source |
| --- | --- | --- | --- |
| P0 | Elixir/OTP version upgrade | Foundational — 5 years behind current | Vision / Blueprint ADR-001 |
| P0 | Distillery→mix release migration | Distillery deprecated since 2020 | Blueprint ADR-002 |
| P1 | Joken 1.x→2.x JWT upgrade | Breaking API change, needs migration plan | Blueprint ADR-004 |
| P1 | OpenCensus→OpenTelemetry migration | OpenCensus EOL, OTEL is successor | Blueprint ADR-003 |
| P2 | Kinesis integration evaluation | Keep JVM sidecar, replace, or deprecate? | Concept open question |
| P2 | Bandit HTTP server evaluation | Pure-Elixir alternative to Cowboy | Blueprint ADR-006 |
| P2 | CloudEvents v1.0 full compliance | Deepen existing support | Vision scope |
| P3 | NATS JetStream support | Evaluate after core modernization | Vision deferred |

### Icebox (Future, Unsequenced)

| Idea | Notes |
| --- | --- |
| GraphQL subscription support | Deferred until core modernization complete |
| gRPC bidirectional streaming | Evaluate after v4 stabilization |
| WebTransport support | Evaluate feasibility post-v4 |
| AsyncAPI spec generation | Auto-generate from route definitions |

---

_Plan is a living document. Update after every session._
