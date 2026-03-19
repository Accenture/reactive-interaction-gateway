# Agent Teams Guide

## Overview

Claude Code's Agent Teams feature parallelizes implementation across independent modules. Multiple Developer teammates run simultaneously on separate file trees, enforced by quality gate hooks.

---

## Agent Skill Binding (Mandatory)

Every spawned teammate **MUST** read its compressed skill file before starting work.

When spawning any teammate, **always** include:

```
FIRST: Read `.claude/agents/_patterns.md` and `.claude/agents/{role}.md`.
These are your compressed skill files — all conventions, patterns, and constraints
are binding for your session.

You are implementing SPEC-{ID}. Read `docs/specs/SPEC-{ID}.md` for requirements.
```

---

## Quick Start

1. Start Claude Code in the project directory
2. Paste the phase prompt template (always include the Spawn Directive)
3. The lead agent spawns teammates; each starts coding in `dontAsk` mode
4. Quality gates run automatically on task completion
5. Wait for all teammates to finish before starting the next phase

---

## Permission Mode: `dontAsk` vs `plan`

**Strongly prefer `dontAsk` mode** for spec-driven teammates.

| Mode      | Behavior                                 | Best For                   |
| --------- | ---------------------------------------- | -------------------------- |
| `dontAsk` | Executes immediately without prompts     | Spec-driven implementation |
| `plan`    | Requires approval before every tool call | Exploratory/risky work     |

**Why `dontAsk` wins for spec-driven work:**

- Specs are detailed enough to serve as the implementation plan
- `plan` mode re-activates after every tool call, causing friction
- Quality gate hooks catch issues at completion time
- Teammates can self-recover from hook failures

---

## Phase Template

```
Create an agent team for Phase {N} implementation.

Spawn two Developer teammates in dontAsk mode.
Each teammate MUST read their skill files first.

Teammate 1 — "{name}-dev":
FIRST: Read `.claude/agents/_patterns.md` and `.claude/agents/backend.md`.
- Implement SPEC-{ID-1} ({Title})
- Module path: src/{module-1}/
- Test path: tests/unit/{module-1}/
- Spec: docs/specs/SPEC-{ID-1}.md

Teammate 2 — "{name}-dev":
FIRST: Read `.claude/agents/_patterns.md` and `.claude/agents/backend.md`.
- Implement SPEC-{ID-2} ({Title})
- Module path: src/{module-2}/
- Test path: tests/unit/{module-2}/
- Spec: docs/specs/SPEC-{ID-2}.md

These modules have ZERO file overlap. Each teammate owns their directory exclusively.

Quality gates enforced via TaskCompleted hook:
- Type check must pass
- Linter must be clean
- All tests must pass

Wait for both teammates to complete before proceeding to Phase {N+1}.
```

---

## Hook Failure Recovery

If a teammate's task completion is blocked by the quality gate hook:

1. **Type failures:** Read errors, fix, retry
2. **Lint failures:** Run linter, fix, retry
3. **Test failures:** Run tests, fix root cause, retry
4. **Hook timeout:** Usually tests hanging — check for unresolved promises

If a teammate can't self-recover:

- Lead agent investigates via `SendMessage`
- As a last resort, manually mark task completed after verifying independently

---

## Token Budget

| Approach                   | Token Cost  | Wall Clock   | Best When                        |
| -------------------------- | ----------- | ------------ | -------------------------------- |
| **Parallel (2 teammates)** | ~2x single  | ~0.5x single | Modules independent, specs solid |
| **Sequential (1 agent)**   | 1x baseline | 1x baseline  | Modules share files              |
| **3+ teammates**           | ~3x+ single | Diminishing  | Rarely justified                 |

**Recommendation:** 2 parallel teammates per phase is the sweet spot.

---

## Best Practices

- **2 teammates per phase** — sweet spot for parallelism vs coordination overhead
- **Phase gating** — wait for Phase N before starting Phase N+1
- **Team lead as fixer** — investigate blocked teammates via SendMessage
- **Quality gate hooks** make `dontAsk` mode safe
- **`dontAsk` for all spec-driven work** — reserve `plan` only for exploratory tasks

---

## Hook Configuration

| Hook          | Script                            | Timeout | Behavior                                |
| ------------- | --------------------------------- | ------- | --------------------------------------- |
| TaskCompleted | `scripts/hooks/task-completed.sh` | 120s    | Blocks completion if quality gates fail |

Hooks are registered in `.claude/settings.json` and apply project-wide.

---

## Worktree Isolation for Overlapping Files

### When to Use

Standard Agent Teams require each teammate to work on **separate file trees** with zero overlap. But sometimes multiple agents need to modify the **same files** — e.g., `overview.go` needs layout changes from a UI agent and data changes from a data agent. Standard parallelism can't handle this safely because both agents would race on the same file.

**Use worktree isolation when:**
- The work is parallelizable (agents don't need each other's output)
- But the file trees overlap (two or more agents need to modify the same file)

### How It Works

Claude Code's Agent tool supports `isolation: "worktree"`, which creates a temporary git worktree — an isolated copy of the repo on its own branch. Each agent works in its own worktree without conflicting with others or the main working tree.

- Each worktree gets a fresh checkout on a temporary branch
- Agents compile and test independently within their worktree
- No file locking or merge conflicts during parallel execution
- The lead (main conversation) orchestrates the merge after agents complete

### Merge Protocol

When all worktree agents complete, the lead copies and merges their changes back:

1. **Copy files from worktree to main:** `cp <worktree-path>/path/to/file ./path/to/file`
2. **If multiple worktrees modified the same file,** merge manually — take the newer logic, re-add any missing parts from the other worktree's version
3. **Build and test after each merge** — don't batch all copies and test once at the end. Incremental verification catches conflicts early
4. **Clean up worktrees** after all changes are merged and tests pass

### When NOT to Use

- **Agents modify entirely different files** — regular Agent Teams (no isolation) are simpler and have less overhead
- **Agents need to see each other's changes in real-time** — use sequential execution instead
- **Single-agent work** — worktree isolation adds complexity with no benefit

### Example

Sprint 6: Three worktree agents ran in parallel — one upgraded `avatar.go`, one enhanced `chronicle.go`, one added the questline to `overview.go`. Each compiled independently. The lead merged results sequentially, resolving one overlap in `overview.go` where both the questline agent and the avatar agent had modified the layout.

---

## Concentration Patterns

Agent Teams parallelize **independent work** on separate file trees. Concentration patterns are different — they converge multiple agents on the **same problem**, each contributing their specialized lens. The goal is richer analysis, not faster throughput.

### Core Principles

1. **Anti-Anchoring:** Agents produce independent analyses BEFORE seeing each other's output. The first perspective must not constrain the others.
2. **Visibility:** All agent perspectives are surfaced to the user — not just the synthesized recommendation. The user sees the full landscape before deciding.
3. **Economy of Force:** Concentration is expensive (3-5x token cost of a single agent). Use it only when the problem warrants multiple lenses. Most problems don't.

---

### Decisive Point (Decisive Concentration)

**Definition:** Concentrate multiple specialist agents at a decisive BUILD problem — a point where getting the answer wrong is expensive and getting it right requires perspectives that no single agent holds.

**Etymology:** Adapted from the German military term Schwerpunkt, meaning "point of main effort" — the place where you concentrate force to achieve a breakthrough. In DDE, it means concentrating agent expertise at the problem that matters most.

#### Trigger Conditions

Decisive Point concentration is warranted when **2 or more** of these conditions are present:

| Condition | Signal |
|-----------|--------|
| **Cross-domain complexity** | The problem spans architecture + performance, or UX + data model, or security + integration |
| **High-stakes irreversibility** | The decision is hard to reverse once implemented (schema migrations, API contracts, security architecture) |
| **Solution space ambiguity** | Multiple viable approaches exist and the team cannot converge on one |
| **Historical rework signal** | Similar decisions in the past led to rework — the IE process memory or retro items indicate this pattern |
| **Blocked progress** | A single agent has been working the problem and cannot make headway alone |

#### When NOT to Use Decisive Point Concentration

- The spec is clear and implementation is straightforward
- The problem lives entirely within one domain (use the domain expert alone)
- Time pressure makes multi-agent analysis impractical
- The decision is easily reversible (just pick one and iterate)

Use **Coup de Main** (decisive single-agent action) instead.

#### Execution: Diverge, Synthesize, Commit

**Phase 1 — Diverge (Parallel, Independent)**

Each agent in the roster analyzes the problem independently. They receive the same problem statement but produce their analysis without seeing the others' output.

```
Lead spawns 3-5 agents with:
- Same problem statement
- Their role-specific skill file
- Instruction: "Produce your independent analysis. Do NOT coordinate with other agents."
- Each agent writes to a separate output section or file
```

**Phase 2 — Synthesize (Lead Agent)**

The lead agent reads all independent analyses and produces a synthesis:
- Where do the perspectives agree? (Convergence = high confidence)
- Where do they disagree? (Divergence = the interesting part — present to user)
- What did one agent see that the others missed? (Unique contribution)
- What is the integrated recommendation?

**Phase 3 — Commit (User Decision)**

Present the synthesis AND all individual perspectives to the user. The user decides. The lead agent records the decision, rationale, and dissenting perspectives in an ADR or spec note.

#### Standard Compositions

| Problem Type | Lead | Supporting Agents | Contrarian Role |
|-------------|------|-------------------|-----------------|
| **Architecture** | Architect | Backend + DevOps + Integration | Mandatory (full ICN) |
| **Performance** | Backend | Architect + DevOps + QE | Advisory (Quick Challenge) |
| **Integration** | Integration | Architect + Backend + DevOps | Advisory (Quick Challenge) |
| **UX-Critical** | CX Designer | Product + Frontend | Mandatory (full ICN) |
| **Data Model** | Architect | Backend + Semantic + Product | Mandatory (full ICN) |
| **Security** | DevOps | Backend + Architect + QE | Advisory (Quick Challenge) |

**Contrarian Role:**
- **Mandatory (full ICN):** For structural decisions (architecture, data model, UX-critical). Full Challenge Report with incongruent representations.
- **Advisory (Quick Challenge):** For implementation decisions (performance, integration, security). Inline Quick Challenge format.

#### Output: Decisive Point Report

```markdown
## Decisive Point Report: {Problem Title}

**Problem Statement:** {the problem being concentrated on}
**Trigger Conditions:** {which conditions from the table were met}
**Roster:** {Lead} + {Supporting 1} + {Supporting 2} [+ Contrarian]

### Independent Analyses

#### {Agent 1 Role} Analysis
{Summary of their independent perspective — key findings, risks, recommendation}

#### {Agent 2 Role} Analysis
{Summary of their independent perspective}

#### {Agent 3 Role} Analysis
{Summary of their independent perspective}

### Convergence Points
- {Where all agents agree — high confidence}

### Divergence Points
- {Where agents disagree — present both sides}
- {What one agent saw that others missed}

### Contrarian Challenge
{Quick Challenge or full ICN findings, depending on problem type}

### Synthesis & Recommendation
**Recommended approach:** {integrated recommendation}
**Rationale:** {why this synthesizes the strongest elements of each perspective}
**Residual risks:** {what risks remain even with this approach}
**Dissenting perspectives:** {which agents disagree and why — preserved for the record}

### Decision
**Chosen:** {user's decision}
**Rationale:** {user's reasoning}
**Recorded in:** {ADR-xxx or SPEC-xxx}
```

#### Examples

1. **Schema migration affecting 3 services:** Architect leads. Backend analyzes migration risk, DevOps analyzes rollback strategy, Integration analyzes consumer impact. Contrarian challenges whether migration is necessary at all.

2. **Performance bottleneck at API gateway:** Backend leads. Architect analyzes whether the bottleneck is architectural (wrong boundaries) vs. implementation (wrong algorithm). DevOps analyzes infrastructure scaling options. QE proposes load test strategy to validate.

3. **New authentication system:** DevOps leads (security). Architect analyzes how auth integrates with service boundaries. Backend analyzes session management options. QE proposes security test coverage. Contrarian does Quick Challenge on whether custom auth is justified vs. managed service.

4. **Data model redesign for multi-tenancy:** Architect leads. Backend analyzes query patterns and migration path. Semantic verifies spec alignment. Product confirms tenant isolation requirements. Contrarian does full ICN on whether multi-tenancy is the right abstraction.

---

### Elastic Defense (Quality Coalition)

**Definition:** Assemble a coalition of agents to diagnose, contain, and remediate a systemic QUALITY problem — one that has grown beyond what a single agent can handle. Named for the military concept of flexible defense that bends without breaking: absorb the attack, identify the weak point, then counter-strike.

**Key difference from Decisive Point:** Decisive Point concentrates to BUILD something. Elastic Defense concentrates to FIX something. The problem already exists and is spreading.

#### Trigger Conditions

| Trigger | Signal | Typical Source |
|---------|--------|---------------|
| **Regression cluster** | 3+ related test failures across modules | QE test run |
| **Spec-code drift cascade** | Semantic gap report shows drift in 3+ specs simultaneously | Semantic review |
| **Performance degradation** | Response times or resource usage crossing warning thresholds across services | Monitoring / DevOps |
| **Security surface expansion** | New vulnerability class or exposure pattern affecting multiple components | Security audit / DevOps |
| **Andon escalation** | IE andon alert at Critical severity with systemic root cause | IE sprint health |

#### Execution: Triage, Diagnose, Contain, Remediate

**Phase 1 — Triage (Lead Agent)**

The lead agent (typically QE for regression, Semantic for drift, DevOps for security/performance) assesses the scope:
- How many components are affected?
- Is the problem spreading or contained?
- What is the blast radius if unaddressed?
- What agents are needed for diagnosis?

```
Lead produces a Triage Report:
- Affected components (list)
- Severity assessment
- Spreading risk (contained / active / accelerating)
- Proposed coalition roster
```

**Phase 2 — Diagnose (Parallel, Independent)**

Each coalition member investigates the problem from their domain perspective. Like Decisive Point, independent analysis first — no anchoring.

- **QE:** Which tests fail, what patterns do the failures share?
- **Semantic:** Which specs are out of alignment, where did drift start?
- **Architect:** Is this a structural issue (wrong boundaries, missing abstractions)?
- **Backend/Frontend:** What code changes correlate with the problem onset?
- **DevOps:** Is this infrastructure-related (resource exhaustion, config drift)?

**Phase 3 — Contain (Coordinated)**

Based on diagnosis, the lead coordinates immediate containment:
- Revert the change that introduced the problem (if identifiable)
- Add temporary guards (feature flags, circuit breakers, rollbacks)
- Prevent the problem from spreading to unaffected components

**Phase 4 — Remediate (Planned)**

After containment, plan the permanent fix:
- Root cause analysis (why did the system allow this?)
- Fix implementation (assigned to appropriate agent)
- Regression test additions (QE)
- Spec updates (Semantic)
- Process improvement (IE observes — what let this happen?)

#### Standard Compositions

| Problem Type | Lead | Diagnostic Agents | Remediation Agents |
|-------------|------|-------------------|--------------------|
| **Regression cluster** | QE | Architect + Semantic | Backend/Frontend + QE |
| **Spec-code drift cascade** | Semantic | Architect + QE | Product + Backend |
| **Performance degradation** | Backend | Architect + DevOps | Backend + DevOps |
| **Security surface expansion** | DevOps | Architect + Backend + QE | DevOps + Backend + Integration |
| **Post-deploy incident** | DevOps | Backend + QE | DevOps + Backend |

**IE Agent:** Always observes Elastic Defense events. Tracks the event in process memory, observes root cause patterns, updates the kaizen backlog with systemic fixes, and flags process gaps that allowed the problem to develop.

**Contrarian:** Reserve role. Not part of standard Elastic Defense assembly, but available if scope expands beyond the original triage (e.g., the root cause turns out to be an architectural assumption that needs challenging).

#### Output: Elastic Defense Report

```markdown
## Elastic Defense Report: {Problem Title}

**Trigger:** {what triggered the assembly}
**Severity:** {Critical / Warning}
**Lead:** {agent role}
**Coalition:** {roster}

### Triage Assessment
- **Affected components:** {list}
- **Blast radius:** {contained / spreading / systemic}
- **Onset:** {when the problem was first observed}
- **Correlation:** {what changed around that time}

### Diagnostic Findings

#### {Agent 1 Role} Findings
{What they found from their domain perspective}

#### {Agent 2 Role} Findings
{What they found}

### Root Cause Analysis
**Primary cause:** {the root cause, not just the symptom}
**Contributing factors:** {what made the system vulnerable}
**Why it wasn't caught earlier:** {what detection gap allowed this}

### Containment Actions
1. {Action taken} — {by whom} — {status}

### Remediation Plan
1. {Fix} — {assigned to} — {target}
2. {Regression test} — {assigned to} — {target}
3. {Spec update} — {assigned to} — {target}

### Process Improvement (IE Observations)
- **Pattern:** {does this match a known process pattern?}
- **Kaizen item:** {K-xxx — systemic fix to prevent recurrence}
- **Process memory update:** {what was learned about how the system behaves}

### Status
{Active / Contained / Remediated / Closed}
```

#### Examples

1. **Authentication regression across 3 services:** QE leads. Architect diagnoses shared auth module as single point of failure. Backend identifies recent refactor that changed token validation. Semantic finds the spec was not updated after refactor. Fix: revert refactor, update spec, add contract tests.

2. **Spec-code drift in data pipeline:** Semantic leads. Finds 4 specs reference field names that were renamed in a migration. Architect confirms the migration was intentional but spec updates were missed. Product updates specs. QE adds drift-detection tests. IE notes "schema migrations without spec updates" as a process gap.

3. **Response time degradation after deployment:** Backend leads. DevOps checks infrastructure (OK). Architect identifies new N+1 query pattern introduced by feature branch. QE provides load test baseline comparison. Fix: add eager loading, add performance regression test.

4. **Security vulnerability in event handling:** DevOps leads. Architect reviews event schema validation gaps. Backend identifies missing input sanitization in 3 event handlers. QE designs security test suite. Integration reviews ACL boundary for exposure. Fix: add validation middleware, update event schema contracts.

---

### Reconnaissance in Force (Exploration Spike)

**Definition:** Send 2-3 agents to probe different areas of an unknown problem space simultaneously. The goal is **understanding, not solving** — map the terrain before committing to a direction.

**When to use:**
- Entering an unfamiliar codebase or domain
- Problem scope is unclear — you don't know what you don't know
- Multiple possible root causes and you need to narrow the field
- Pre-concentration: use Recon to determine whether a Decisive Point concentration is even needed

**Execution:**
1. Lead assigns 2-3 agents to explore different areas of the problem space
2. Each agent probes their area and reports findings: what they found, what surprised them, what remains unclear
3. Lead synthesizes findings into a **Terrain Map**: known areas, unknown areas, recommended next steps
4. Based on the map, the team decides: proceed with a single agent, escalate to Decisive Point, or do another Recon pass on a specific area

**Output: Terrain Map**

```markdown
## Terrain Map: {Problem Area}

**Scouts:** {agent roster}
**Purpose:** {what we were trying to understand}

### Known Terrain
- {What we confirmed or discovered — with evidence}

### Unknown Terrain
- {What remains unclear — what would we need to investigate further?}

### Surprises
- {What we didn't expect to find}

### Recommended Next Step
{Single agent (Coup de Main) | Decisive Point (need convergence) | Another Recon pass (need more data) | No action needed}
```

---

### Battle Group (Fire Brigade — Rapid Composite Task Force)

**Definition:** Rapidly assemble a temporary task force of 2-4 **composite agents** — each built from an existing archetype cross-loaded with specializations from other agents — to respond to an emergent situation. The Battle Group is mission-intent-driven: the lead states the desired end state, and the agents maneuver to achieve it.

**Etymology:** Adapted from the German military term Kampfgruppe for "battle group" — a temporary combined-arms unit assembled from available forces for a specific tactical situation, then dissolved after the mission.

**Key difference from Decisive Point:** Decisive Point is deliberate, planned, and runs a full protocol (Diverge/Synthesize/Commit). Battle Group is rapid, emergent, and mission-intent-driven. Decisive Point is a siege; Battle Group is a cavalry charge.

#### Trigger Conditions

| Trigger | Signal | Typical Source |
|---------|--------|---------------|
| **Emergent multi-agent need** | Situation requires 2+ specialized perspectives but wasn't anticipated at sprint planning | Mid-sprint discovery |
| **Formal Objection escalation** | Unanimous Halt (Tier 2) → command decision → "assemble a task force" | Objection convergence |
| **Decisive point shift** | The real problem turns out to be different from what the sprint planned for | Agent observation during build |
| **Fire brigade need** | Something is on fire and the standard patterns are too slow to assemble | Time-critical quality or build issue |

#### When NOT to Use Battle Group

- The situation is planned and high-stakes — use **Decisive Point** (you have time for the full protocol)
- The situation is a systemic quality problem with known scope — use **Elastic Defense** (triage/diagnose/contain/remediate is the right protocol)
- One agent can handle it — use **Coup de Main**
- You don't understand the problem yet — use **Reconnaissance in Force** first

#### Execution: Enlist, Deploy, Synthesize, Dissolve

**Phase 1 — Enlist (Lead Agent)**

The lead defines the mission and assembles the task force:

```
Mission Intent:
- Problem: {what's happening}
- Desired end state: {what we need to achieve}
- Constraints: {what we cannot do}
- Reason: {why this matters now}

Task Force:
- Agent 1: {archetype} + {cross-training} — role: {mission role}
- Agent 2: {archetype} + {cross-training} — role: {mission role}
- Agent 3 (if needed): {archetype} + {cross-training} — role: {mission role}
```

For each agent, the lead composes a spawn prompt that includes:
1. `_patterns.md` (always — includes Mission-Type Tactics doctrine)
2. Primary skill file (`.claude/agents/{archetype}.md`)
3. Cross-training sections from 1-2 other agent skill files (relevant portions only)
4. Mission context (spec sections, findings, event history relevant to the mission)
5. Mission role assignment within the task force

**Phase 2 — Deploy (Parallel or Phased)**

Agents are spawned and operate within the commander's intent. Each agent:
- Reads their composite skill loading
- Executes their mission role
- May raise a Formal Objection if they discover the mission intent needs adjustment
- Reports findings to their output area

**Phase 3 — Synthesize (Lead Agent)**

The lead reads all agent outputs and produces a synthesis:
- What did each agent find?
- Where do they converge? (High confidence)
- Where do they diverge? (Present both perspectives to user)
- What is the integrated recommendation?

**Phase 4 — Dissolve**

- Key findings logged as `agent_note` events for institutional memory
- Battle Group ceases to exist — agents do not persist
- If the mission revealed a larger issue, the lead recommends the appropriate follow-up pattern (Decisive Point, Elastic Defense, or sprint re-planning)

#### Deterministic Roster Templates

When the lead wants structure over improvisation, these pre-built shapes are available. **These are starting points, not mandates** — using a template verbatim when the situation calls for a different composition is Directive Control (CDR-005).

| Shape | Lead | Supporting Agents | Use When |
|-------|------|-------------------|----------|
| **Perf Investigation** | Backend (+ DevOps cross-train) | DevOps (+ Backend cross-train) + QE (analysis sub-persona) | Performance regression, unknown cause |
| **Spec Drift Rapid** | Semantic | Architect + Product | Spec-code drift found mid-sprint |
| **Security Hotfix** | DevOps (+ Backend cross-train) | Backend + QE (security sub-persona) | Vulnerability discovered during build |
| **Design Pivot** | Product (+ CX cross-train) | CX + Architect | UX assumption invalidated mid-sprint |
| **Integration Emergency** | Integration | Backend + DevOps | External system contract broken |

#### Output: Battle Group After-Action

```markdown
## Battle Group After-Action: {Mission Title}

**Trigger:** {what triggered the assembly}
**Mission Intent:** {the stated problem + desired end state}
**Task Force:** {roster with roles}
**Duration:** {how long the mission took}

### Agent Findings

#### {Agent 1 Role} ({Archetype} + {Cross-training})
{What they found, what they did, what they recommend}

#### {Agent 2 Role} ({Archetype} + {Cross-training})
{What they found}

### Synthesis
**Convergence:** {where agents agreed}
**Divergence:** {where they disagreed — preserved for record}
**Recommendation:** {integrated recommendation}

### Outcome
**Command Decision:** {what the user decided}
**Follow-up:** {None | Decisive Point needed | Sprint re-plan | Elastic Defense}

### Harvested Findings
- {Key finding logged as agent_note event}
```

#### Examples

1. **Mid-sprint performance regression:** During WI-26.2 implementation, Backend agent notices TUI render times have degraded. Raises Formal Objection (Tier 1). User issues command decision: "Assemble Perf Investigation Battle Group." Lead enlists Backend+DevOps (lead, profiling focus), DevOps+Backend (infrastructure analysis), QE (baseline comparison). Battle Group identifies N+1 query in new conform scanner. Fix applied. Battle Group dissolves.

2. **Formal Objection escalation:** During parallel build work, both Backend and Architect independently flag that the spec's data model won't support a discovered edge case. Unanimous Halt triggers. User reviews, issues command decision: "Assemble Design Pivot Battle Group." Product+CX lead, Architect analyzes structural impact, Backend proposes migration path. Spec updated. Battle Group dissolves.

3. **Security discovery:** QE agent running tests discovers an input validation gap in event handling. Raises Formal Objection. User assembles Security Hotfix Battle Group. DevOps+Backend leads, Backend implements fix, QE writes regression tests. After-action logged. Battle Group dissolves.

---

### Coup de Main (Decisive Single-Agent Action)

**Definition:** When a problem is clear, well-scoped, and within one domain, use a single agent decisively. Don't over-concentrate.

**This is the anti-pattern documentation:** Concentration patterns are powerful but expensive. Using Decisive Point for a problem that one agent can handle is waste (over-processing). Using Elastic Defense for a single test failure is overkill.

**When to use Coup de Main (i.e., just use one agent):**
- The spec is clear and the implementation path is obvious
- The problem lives entirely within one domain
- The fix is straightforward and low-risk
- Time pressure makes multi-agent analysis impractical
- The decision is easily reversible

**Rule of thumb:** If you can state the problem, the approach, and the expected outcome in 3 sentences, you don't need a concentration pattern. Just execute.

---

### Decision Tree: Which Pattern?

```
Is the work independent?
├── YES, separate files → Agent Teams (parallel branches)
├── YES, but overlapping files → Agent Teams with worktree isolation
├── NO, same problem → Is it a BUILD problem or a QUALITY problem?
│   ├── BUILD problem:
│   │   ├── Clear, one domain? → Coup de Main (single agent)
│   │   ├── Unknown terrain? → Reconnaissance in Force (explore first)
│   │   ├── Planned, high-stakes? → Decisive Point (concentrate to decide)
│   │   └── Emergent, needs rapid response? → Battle Group (fire brigade)
│   └── QUALITY problem:
│       ├── Single, isolated issue? → Coup de Main (single agent fix)
│       ├── Systemic, planned scope? → Elastic Defense (coalition)
│       └── Systemic, emergent? → Battle Group (fire brigade)
└── Unknown → Reconnaissance in Force

Battle Group can also be triggered BY Formal Objection:
Unanimous Halt → command decision → Battle Group assembly
```

| Pattern | Purpose | Agents | Token Cost | When |
|---------|---------|--------|------------|------|
| **Agent Teams** | Parallel independent work | 2-3 | ~2-3x | Separate file trees, solid specs |
| **Agent Teams + Worktree** | Parallel with file overlap | 2-3 | ~2-3x | Overlapping files, merge at end |
| **Coup de Main** | Decisive single-agent action | 1 | 1x | Clear problem, one domain |
| **Reconnaissance in Force** | Exploration spike | 2-3 | ~2-3x | Unknown terrain, unclear scope |
| **Decisive Point** | Decisive build concentration | 3-5 | ~3-5x | Cross-domain, high-stakes, ambiguous |
| **Elastic Defense** | Quality coalition | 3-5 | ~3-5x | Systemic quality degradation |
| **Battle Group** | Rapid fire brigade | 2-4 | ~2-4x | Emergent, unplanned, Formal Objection escalation |
