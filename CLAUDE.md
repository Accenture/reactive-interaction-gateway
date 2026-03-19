# reactive-interaction-gateway — Project Context

**Project:** reactive-interaction-gateway (RIG)
**Version:** 3.0.0
**Phase:** Active Development (DDE Retrofit)
**Status:** Active — 37 test files, ~114 modules, 0 specs (pre-DDE)

---

## Session Start (MANDATORY)

At the start of every session, before any other work, run the DDE status scan to load project context:

```bash
# Prefer the Go binary if built; fall back to shell script
# Use --brief to suppress CLI narration — Claude emits the Athena session-open beat
# as visible text output (not buried in collapsed bash results)
if command -v dde >/dev/null 2>&1; then
  dde status --brief --path .
elif [ -x tools/dde/dde ]; then
  tools/dde/dde status --brief --path .
else
  bash scripts/dde-status.sh .
fi
```

This gives you the current phase progress, sprint state, process health, and session mode before you begin. Use this output to inform your work — do not ask the user to repeat information the scan already provides.

**IMPORTANT:** After reading the status output, emit the **Session Open** Athena beat as your own text response (not inside a tool call). This ensures it's visible to the user, not collapsed inside bash output. See the output style for the Session Open beat format.

After the status scan, ask the user:

> **Would you like to bring up Athena?** (Launch `dde athena` in a separate terminal for the companion sidebar and chronicle overlay.)

If yes, instruct the user to run `dde athena` (or `tools/dde/dde athena`) in a separate terminal window. Athena provides persistent narrative context, session history, and the Scribe-Adept avatar alongside the main Claude Code session.

---

## Session Mode (ASK AT SESSION START)

After running the status scan, confirm the session mode. If the scan detected a mode (Kit Improvement or Project Build), state it and confirm with the user. Only ask if the scan returned "Unknown":

> **Are you improving the kit itself, or building a new project with it?**

| Mode | What it means | Artifacts go to |
| ---- | ------------- | --------------- |
| **Kit Improvement** | Changing agents, templates, workflows, docs that ship with the kit | `.kit-dev/` |
| **Project Build** | Using the kit to build a real product | `docs/planning/` |

**Remember this decision for the entire session.** It determines where session boundary artifacts (delivery plan updates, retros) are written:

- **Kit Improvement** — update `.kit-dev/DELIVERY_PLAN.md`, write retros to `.kit-dev/retrospectives/`. Do NOT modify the template placeholders in `docs/planning/DELIVERY_PLAN.md` or this file's stats/timestamps — those stay pristine for adopters.
- **Project Build** — update `docs/planning/DELIVERY_PLAN.md`, write retros to `docs/planning/retrospectives/`, update stats in this file. Normal workflow.

---

## Cumulative Stats

| Metric         | Value |
| -------------- | ----- |
| Tests          | 37 files (ExUnit) |
| Test Suites    | ~15   |
| Specifications | 0     |
| Modules        | 114   |

---

## Project Overview

### Domain

- **Specialization:** Event-driven API gateway and real-time messaging hub for microservices
- **Users:** Platform engineers, backend developers, and DevOps teams building event-driven architectures

### Critical Constraints

- Elixir/Erlang ecosystem — leverages OTP for fault tolerance and concurrency
- Must maintain backward compatibility with existing RIG v3 API contracts and event schemas

### Project Context (Existing Codebase)

RIG is a mature, open-source event-driven API gateway originally created by Accenture. It bridges frontend clients and backend microservices with bidirectional communication:

- **Inbound Gateway:** Routes client HTTP requests to backends (sync, async, or via message brokers)
- **Outbound Gateway:** Pushes backend events to connected clients via WebSocket, SSE, or long-polling
- **Event Routing:** Subscription-based filtering with JSON Pointer extractors and CloudEvents support
- **Message Brokers:** Kafka, NATS, AWS Kinesis integration
- **Auth:** JWT validation, token blacklisting, session management
- **Observability:** Prometheus metrics, OpenCensus distributed tracing (Jaeger/Zipkin), structured logging

The project has been in maintenance/abandonware state. DDE is being applied to revitalize and modernize it.

---

## Technology Stack

| Layer             | Technology                                              |
| ----------------- | ------------------------------------------------------- |
| **Language**      | Elixir 1.11+ (Erlang/OTP 23+)                         |
| **Framework**     | Phoenix 1.5 + Cowboy HTTP server                       |
| **Database**      | ETS (in-memory) + external event stores (Kafka, NATS, Kinesis) |
| **Cache**         | ETS-based memoization (Memoize library)                |
| **Testing**       | ExUnit + ExCoveralls + Mox + StreamData (property-based) |
| **CI/CD**         | GitHub Actions + Docker multi-stage builds              |
| **Observability** | Prometheus + OpenCensus (Jaeger/Zipkin) + structured JSON logging |

### Additional Stack Details

| Component         | Technology                                              |
| ----------------- | ------------------------------------------------------- |
| **HTTP Server**   | Cowboy 2.x (via plug_cowboy)                           |
| **JSON**          | Jason + Jaxon (streaming parser)                       |
| **Serialization** | Apache Avro (erlavro) + Confluent Schema Registry      |
| **Rate Limiting** | ExRated (leaky bucket)                                 |
| **Tracing**       | OpenCensus with W3C Trace Context support              |
| **Deployment**    | Docker + Kubernetes + Helm v3                          |
| **Release**       | Distillery (OTP releases)                              |

---

## Architecture Overview

### Core OTP Applications

| Application            | Purpose                                    | Key Modules                              |
| ---------------------- | ------------------------------------------ | ---------------------------------------- |
| `rig`                  | Core framework — subscriptions, events, JWT | `EventFilter`, `Subscription`, `JWT`    |
| `rig_inbound_gateway`  | Client→backend request routing             | `Proxy`, `ApiProxy.Handler.*`           |
| `rig_inbound_gateway_web` | Phoenix web endpoints (client-facing)   | `Router`, controllers                    |
| `rig_outbound_gateway` | Backend→client event forwarding            | `KinesisToFilter`, event stream adapters |
| `rig_api`              | Internal management API                    | v2/v3 controllers                        |
| `rig_kafka`            | Kafka consumer/producer integration        | Brod-based consumers                     |
| `rig_metrics`          | Prometheus metrics collection              | `PrometheusExporter`                     |
| `rig_cloud_events`     | CloudEvents spec support                   | `Parser.*`                               |

### Key Source Paths

| Path                          | Purpose                        |
| ----------------------------- | ------------------------------ |
| `lib/rig/`                    | Core framework modules         |
| `lib/rig_inbound_gateway/`    | Inbound proxy & event publish  |
| `lib/rig_outbound_gateway/`   | Outbound event forwarding      |
| `lib/rig_api/`                | Management API                 |
| `lib/rig_kafka/`              | Kafka integration              |
| `lib/rig_cloud_events/`       | CloudEvents parsing            |
| `config/`                     | Elixir configuration           |
| `deployment/`                 | K8s & Helm templates           |
| `test/`                       | ExUnit test files              |
| `integration_tests/`          | Integration test suite         |

---

## Persona-Based Development

### Personas (12 agents)

#### Core Workflow Personas

| Persona                              | Focus              | Primary Outputs                      |
| ------------------------------------ | ------------------ | ------------------------------------ |
| **Product Designer / Product Manager** | Specifications   | SPEC-\*.md files, delivery plans     |
| **Architect**                        | System Design      | Design docs, ADRs, API specs         |
| **Frontend Engineer**                | UI Implementation  | UI components, frontend tests        |
| **Backend Engineer**                 | Service Logic      | Modules, APIs, unit tests            |
| **Quality Engineer (QE)**            | Testing            | Integration/E2E tests, BDD scenarios |
| **DevOps**                           | Deploy & Operate   | Infrastructure, CI/CD, K8s           |
| **CX Designer**                      | UI/UX Design       | Visual QA, a11y audits, design audit |

#### Cross-Cutting Personas

| Persona                              | Focus              | Primary Outputs                      |
| ------------------------------------ | ------------------ | ------------------------------------ |
| **Contrarian**                       | Assumption Challenge | Challenge reports, shadow cabinet    |
| **Contrarian (Editorial)**           | Plain-Language Challenge | Editorial structured dissent      |
| **Industrial Engineer**              | Continuous Improvement | Kaizen backlog, waste findings, retro tracking |
| **Semantic Reviewer**                | Spec-Code Alignment | Gap reports, impact analysis, drift  |
| **Coherence Architect**              | Document Coherence | Coherence audits, thread maps, narrative consistency |

#### Specialized Personas

| Persona                              | Focus              | Primary Outputs                      |
| ------------------------------------ | ------------------ | ------------------------------------ |
| **Integration & External Systems**   | System Boundaries  | Event schemas, legacy contracts, ACL design |

### Workflow

```
Product Designer / Product Manager -> Architect -> Frontend/Backend -> QE -> Product Designer / Product Manager
             (spec)                   (design)        (code)        (test)           (accept)
                                         ^                                               |
                                    CX Designer                                    DevOps (deploy)
                                 (design critique)                                       |
                                                                                  Semantic Reviewer
                                                                                 (spec-code verify)
```

### Workflow Rules

All work follows a **phase-ordered workflow** (see `.claude/agents/_patterns.md` for full details):

1. **Phase Sequence:** Vision → Concept → Blueprint → [Experience Design] → Specification → Build → Verify (strictly sequential; Experience Design is optional, see below)
2. **Challenge Gates:** Contrarian challenge session is MANDATORY after every Vision, Concept, Blueprint, and Experience Design session
3. **Experience Design (optional):** Required for any feature with a user-facing interface (CLI output, TUI, visual design). Skipped for pure backend/infrastructure. Led by CX Designer persona. Produces `docs/planning/EXPERIENCE-*.md`.
4. **Spec Granularity:** Specs should be feature-sized (≤5 FRs, ≤10 ACs, demo-able as one capability). Large features break into a foundation spec + capability specs. Skeletal specs at sprint planning; full specs at sprint begin.
5. **Skill Activation:** Pre-Blueprint agents (Product, Architect, Contrarian, IE, Coherence Architect, Semantic) are tech-agnostic; Post-Blueprint agents (Frontend, Backend, QE, CX, DevOps, Integration) are tech-specific
6. **Decision Protocol:** One decision at a time, 2–3 options, recommendation with rationale, wait for user

### Specification-First Requirement

**Every enhancement MUST have a written specification (`docs/specs/SPEC-*.md`) before implementation begins.** No code is written without a spec. See `docs/development/PERSONA_WORKFLOW_GUIDE.md` for full details.

### Session Boundary Protocol (MANDATORY)

Every session must execute this checklist at close. **Artifact paths depend on session mode** (see Session Mode above):

0. **Update delivery plan in real-time** — when ad hoc work items are committed to mid-session, add them to the active sprint immediately (not at session close). The dashboard reads this file live.
0b. **Plan consistency check** — if `dde status` or `dde board` shows plan staleness warnings, fix the delivery plan BEFORE continuing work.
1. Run tests + type check — verify passing (skip if planning-only)
2. Update delivery plan — test counts, completed work, backlog changes
3. Update project stats (Project Build mode only) — update this file's stats/timestamps
4. Write retro — full for sprint end, partial for mid-sprint sessions
5. **Athena beat audit** — count Athena narrative beats emitted during the session.
6. **Run `dde close`** to generate the session journal skeleton
7. Fill tier-2 frontmatter in the journal entry
8. **Commit all changes, merge feature branch to main, delete feature branch**

### Quality Gates

- **Definition of Ready (DoR):** 16 checkpoints before development
- **Definition of Done (DoD):** Across 8 categories (code, tests, types, lint, coverage, docs, demo, regression)

---

## Git & Branching Workflow

### Branch Strategy

```
feature/* --PR--> dev --sprint merge--> main
fix/*     --PR--> dev
docs/*    --PR--> dev
```

| Branch      | Purpose                    | Protected | Merges To |
| ----------- | -------------------------- | --------- | --------- |
| `main`      | Stable, verified releases  | Yes       | ---       |
| `dev`       | Integration branch         | Yes       | `main`    |
| `feature/*` | Individual feature work    | No        | `dev`     |
| `fix/*`     | Bug fixes                  | No        | `dev`     |
| `docs/*`    | Documentation-only changes | No        | `dev`     |

### Branch Naming

Use the pattern `<type>/<spec-id>-<short-description>`:

```
feature/SPEC-AUTH-001-login-flow
fix/api-timeout-handling
docs/sprint-1-retro
```

---

## Commands Reference

```bash
# Testing (Elixir)
mix test                  # Run all tests
mix test --cover          # Run with coverage
mix credo                 # Static analysis / linting
mix dialyzer              # Type checking

# Development
mix deps.get              # Fetch dependencies
iex -S mix                # Start interactive shell with app
mix phx.server            # Start Phoenix server

# Docker
docker build -t rig .     # Build Docker image
docker-compose up -d      # Start services

# DDE Tool (if built)
dde status                # Phase progress + challenge gates + health
dde board                 # Kanban sprint board
dde health                # IE process health summary
scripts/dde-status.sh     # Zero-dependency shell fallback
```

---

## Key References

| File                                                  | Purpose                           |
| ----------------------------------------------------- | --------------------------------- |
| `docs/planning/DELIVERY_PLAN.md`                      | Sprint backlog + roadmap (project)|
| `docs/specs/SPEC_REGISTRY.md`                         | All specifications                |
| `docs/specs/SPEC_TEMPLATE.md`                         | Spec template (standalone)        |
| `docs/specs/SPEC_QUALITY_RUBRIC.md`                   | Spec grading system               |
| `docs/planning/templates/CHALLENGE_REPORT_TEMPLATE.md`| Challenge report template         |
| `docs/development/PERSONA_WORKFLOW_GUIDE.md`          | Persona workflow details          |
| `docs/development/AGENT_TEAMS_GUIDE.md`               | Parallel agent execution          |
| `docs/planning/KAIZEN_BACKLOG.md`                     | IE agent improvement backlog      |
| `docs/planning/IE_PROCESS_MEMORY.md`                  | IE agent process observations     |
| `.dde/sessions/`                                      | Session logs (adventure journal)  |
| `.claude/agents/*.md`                                 | Agent persona skill files         |
| `docs/planning/VISION.md`                             | Project vision document           |
| `docs/planning/CONCEPT.md`                            | Project concept document          |
| `docs/architecture/SOLUTION_BLUEPRINT.md`             | Solution blueprint                |

---

_Last Updated: Sprint 0 — DDE initialization and codebase scan_
