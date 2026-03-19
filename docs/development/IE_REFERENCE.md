# Industrial Engineer — Reference Material

> Templates, detection patterns, statistical methods, and detailed protocols. Referenced by the IE agent file but kept separate to stay within the spawn truncation budget (10KB).

---

## Maneuver Warfare Concepts (Lind / Boyd)

William Lind's *Maneuver Warfare Handbook* and John Boyd's OODA loop theory complement lean manufacturing. Where lean focuses on eliminating waste in steady-state production, maneuver warfare focuses on winning in dynamic environments through speed, focus, and decentralized initiative.

### OODA Loop (Observe -> Orient -> Decide -> Act)

The team that cycles through OODA faster outmaneuvers competitors:
- **Observe:** User feedback, test results, production metrics, market signals
- **Orient:** Pattern recognition, mental models, bias awareness (Contrarian's role)
- **Decide:** Decision Presentation Protocol, one decision at a time
- **Act:** Build/Verify phases

**IE application:** Track OODA cycle time. Long orientation (analysis paralysis) and long decide phases (indecision) are bottlenecks. Speed of decision-making beats quality of individual decisions — fast cycles enable rapid course correction.

### Decisive Point (Main Effort)

One primary mission. When everyone understands it, they set aside secondary tasks to support it.
- Verify ONE clear sprint goal at planning, not a laundry list
- WIP limits are the operational mechanism for the decisive point
- Sprint goal should be statable in one sentence

### Mission-Type Tactics

Give subordinates the **intent** (what to achieve) and freedom to figure out **how**. Specs say WHAT; agents decide HOW. Specs that over-prescribe implementation violate Mission-Type Tactics.

### Tempo, Surfaces/Gaps, Decentralized Decision-Making

- **Tempo:** Invest effort where it accelerates the OODA loop
- **Surfaces and gaps:** Put effort into riskiest, least-understood areas first
- **Decentralized:** Push decisions to the lowest level with sufficient information

---

## Improvement Assessment Template

```
## Improvement Assessment: {Title}

**Proposed Improvement:** {description}
**Target Metric:** {what it aims to improve}
**Hypothesis:** If we {change}, then {metric} will {improve by amount}. Evaluate after {N sprints}.

### Uncertainty Decomposition
- **Epistemic component:** {what we don't know but could learn}
- **Aleatoric component:** {what is inherently variable and cannot be reduced}
- **Assessment:** {primarily epistemic | primarily aleatoric | mixed}

### Signal vs. Noise Check
- **Data points:** {N observations}
- **Variation type:** {common cause | special cause | insufficient data}
- **Verdict:** {signal — act on it | noise — do not optimize | insufficient data}

### Tennis Court Trace
- **Current flow:** {steps, wait points, handoffs}
- **Proposed flow:** {steps, wait points, handoffs}
- **Net complexity:** {simpler | same | more complex}

### Recommendation
{Proceed | Investigate further | Reframe | Accept variance | Revert}
```

---

## Full 7-Waste Taxonomy

| Waste Type | Detection Signal | Example |
|---|---|---|
| **Waiting** | Items blocked, specs awaiting review, pending decisions | "WI-2.3 blocked 3 days awaiting scope decision" |
| **Defects** | Rework items, spec-code divergence, failed quality gates | "3 of 8 items required rework after QE review" |
| **Inventory** | Unmerged branches, specs written but not implemented | "Branch open for 14 days" |
| **Overproduction** | Features built beyond spec scope, gold-plating | "Retry logic not in any FR" |
| **Over-processing** | Excess review rounds, empty audits | "5 review rounds before implementation" |
| **Motion** | Context switching, searching for information | "Switched between 4 specs to find acceptance criteria" |
| **Transportation** | Handoffs that add latency without value, reformatting | "Same metric in 3+ places" |

### Mura (Unevenness) and Muri (Overburden)

- **Mura:** Irregular workload — flag when sprint capacity varies >50% from mean
- **Muri:** Unsustainable pace — flag when same quality steps skipped 2+ sprints

---

## Structured Muda Detection Patterns

### Waiting Detection
| Signal | Data Source | Measurement | Andon Threshold |
|--------|-----------|-------------|-----------------|
| Blocked WIs | Delivery plan | >2 day gap between status changes | >2 items blocked >2 days |
| Stale branches | Git log | No commits for >3 days | >1 branch stale >5 days |
| Pending decisions | Session history | Questions raised but not answered | >3 open decisions |
| Review queue | Spec registry | Specs awaiting review | >2 specs in queue >2 days |

### Defects Detection
| Signal | Data Source | Measurement | Andon Threshold |
|--------|-----------|-------------|-----------------|
| CDR count | CDR docs | New CDRs this sprint | >2 CDRs in one sprint |
| Fix branches | Git log | fix/* branches merged | >25% of branches are fixes |
| Rework ratio | Delivery plan | Rework WIs / total WIs | >25% rework rate |
| Spec-code divergence | Semantic gap reports | Divergent + Missing FRs / total | >15% divergence |

### Inventory Detection
| Signal | Data Source | Measurement | Andon Threshold |
|--------|-----------|-------------|-----------------|
| Open branches | Git log | Unmerged branches >5 days | >3 open branches |
| Unscheduled specs | Spec registry | Complete specs not assigned | >2 unscheduled specs |
| Completed but unmerged | Delivery plan | WIs done, branch not merged | >1 item lingering >2 days |

### Overproduction Detection
| Signal | Data Source | Measurement | Andon Threshold |
|--------|-----------|-------------|-----------------|
| Untraceable code | Semantic gap reports | Code not mapping to any FR | >3 undocumented behaviors |
| Gold-plating | Code review | Features beyond spec scope | Any feature not in spec |

### Over-processing Detection
| Signal | Data Source | Measurement | Andon Threshold |
|--------|-----------|-------------|-----------------|
| Review rounds | Spec history | Cycles before approval | >3 rounds on any spec |
| Empty audits | Audit results | Zero-finding audits | >50% empty audits |
| Process with no consumer | Agent files | Artifacts nobody reads | Any unreferenced template |

### Motion Detection
| Signal | Data Source | Measurement | Andon Threshold |
|--------|-----------|-------------|-----------------|
| Context switches | Git log | Unrelated files in single commit | >5 unrelated files |
| Information search | Session observation | Time finding docs | Repeated searches |

### Transportation Detection
| Signal | Data Source | Measurement | Andon Threshold |
|--------|-----------|-------------|-----------------|
| Data reformatting | Doc comparison | Same info in different formats | Same metric in >3 places |
| Copy-paste content | Doc diff | Identical paragraphs across files | Duplicated content |

---

## Bottleneck Identification (Theory of Constraints)

At sprint boundaries:
1. **Identify:** Which stage has the most items queued? That's the constraint.
2. **Exploit:** Is the constraint fully utilized?
3. **Subordinate:** Are upstream stages producing faster than the constraint can consume?
4. **Elevate:** Only after exploit and subordinate — add capacity.
5. **Repeat:** Once the constraint moves, find the new one.

---

## Statistical Quality Control (FR-4)

### Tracked Metrics
| Metric | Source | Minimum Data |
|---|---|---|
| Cycle time | Delivery plan (spec creation -> DoD) | 3 sprints |
| Throughput | Work items completed per sprint | 3 sprints |
| Rework rate | Fix commits / total commits | 3 sprints |
| Test pass rate | Test suite results per sprint | 3 sprints |
| Retro item resolution rate | Items resolved / total | 5 sprints |

### Control Chart Logic

With >=3 sprints of comparable data:
1. Calculate control limits: Mean +/- 3 standard deviations
2. Classify: common cause (within limits) vs special cause (outside or non-random pattern)
3. Process capability: can the system consistently meet targets?

### Sprint-Type Segmentation

| Sprint Type | Characteristics | Compare With |
|---|---|---|
| Build | Feature implementation, high test output | Other build sprints |
| Hardening | Bug fixes, regression, tech debt | Other hardening sprints |
| Spike/Research | Investigation, design, low code output | Other spike sprints |
| Infrastructure | DevOps, CI/CD, deployment | Other infra sprints |

### Validation Evidence

Validated against 149 sprints across multiple projects:
- Common vs special cause patterns emerge after sprint 5
- Sprint-type segmentation is critical (build sprints 3-5x test output of spike sprints)
- Wait for 5+ comparable sprints before drawing control limits
- Most actionable metric: **review queue depth**

### Control Chart Report Template

```
## Control Chart Report -- Sprint {N}

| Metric | Value | Mean | UCL | LCL | Status |
|---|---|---|---|---|---|
| Cycle time | {N} days | {mean} | {ucl} | {lcl} | {Within limits / Special cause} |
| Throughput | {N} items | {mean} | {ucl} | {lcl} | {Within limits / Special cause} |
| Rework rate | {N}% | {mean}% | {ucl}% | {lcl}% | {Within limits / Special cause} |
| Test pass rate | {N}% | {mean}% | {ucl}% | {lcl}% | {Within limits / Special cause} |

{N} sprints of data available. {Sufficient / Insufficient} for statistical claims.
```

### SPC Data Collection Protocol

| Metric | Collection Method | Source |
|--------|------------------|--------|
| Cycle time | Parse delivery plan: WI creation -> completion | Delivery plan + git log |
| Throughput | Count WIs with status "Complete" in active sprint | Delivery plan |
| Rework rate | fix/* branches merged + rework WIs / total WIs | Git log + delivery plan |
| Test pass rate | CLAUDE.md stats or test suite output | CLAUDE.md or test output |
| Retro resolution | Resolved AIs / total AIs | Retro documents |

---

## Carry-Forward Escalation

| Age | Level | IE Response |
|-----|-------|-------------|
| 1 sprint | Warning | Note in health briefing, monitor |
| 2 sprints | Blocking | Andon: must be completed, descoped, or abandoned this sprint |
| 3+ sprints | Critical | Chronic carry-forward — abandon or make decisive point |

---

## PDCA Cycle Management (FR-5)

**Mapping:** Plan (sprint planning) -> Do (execution) -> Check (sprint close) -> Act (retro)

```
## PDCA Cycle: {ID} -- {Title}

**Hypothesis:** If we {change}, then {metric} will improve by {amount}
**Target Metric:** {metric} -- Current: {value}, Target: {value}
**Sprint:** {N}
**Status:** Plan | Do | Check | Act | Complete | Abandoned

### Plan / Do / Check / Act
{Fill at each phase}
```

Rules: explicit hypothesis, tracked in kaizen backlog, max 2 concurrent PDCA cycles.

---

## Andon Signal System (FR-3)

| Trigger | Default Threshold | Severity |
|---|---|---|
| Quality gate failure rate | >30% of sprint items | Critical |
| Item blocked duration | >2 calendar days | Warning |
| Cycle time spike | >1.5x rolling average (>=3 sprints) | Warning |
| Rework rate | >25% of items | Warning |
| Retro item unresolved | >2 sprints | Warning |
| Test pass rate drop | >20% decline | Critical |

```
## ANDON ALERT: {Alert Type}
**Severity:** Critical | Warning
**Metric:** {name} = {value}
**Threshold:** {threshold}
**Trend:** {improving | stable | degrading} over {N} sprints
**Recommended Action:** {next step}
```

---

## Bug Spiral Detection

**Triggers:**
- **Spiral:** 3 small fix attempts without resolution -> andon + root cause analysis
- **Big-swing:** 1 large fix without prior analysis -> pause for analysis

**Protocol:** IE raises andon -> 5 Whys (IE + QE) -> Ishikawa diagram -> Root cause graph -> Fix targets root cause -> QE writes CDR

---

## Kanban Flow Supervision (FR-1)

| Stage | Source | WIP Default |
|---|---|---|
| Vision | VISION*.md | 1 |
| Concept | CONCEPT*.md | 1 |
| Blueprint | SOLUTION_BLUEPRINT*.md | 1 |
| Specification | SPEC-*.md (Planning/In Progress) | 3 |
| Build | Delivery plan items (In Progress) | 5 |
| Verify | Items awaiting review | 3 |

WIP limits are guidelines, not hard gates. Surface violations as waste findings.

---

## Lean Software Development Principles (FR-9)

| Principle | What to Check | Violation Signal |
|---|---|---|
| Eliminate waste | Activities that don't trace to user value? | Non-value-adding steps |
| Build quality in | Defects caught early or late? | Defects found in Verify that could've been caught in Spec |
| Create knowledge | Retro items applied? Lessons learned? | Same mistakes repeated |
| Defer commitment | Tech decisions made too early? | Tech choices before Blueprint |
| Deliver fast | Small batches? Short cycles? | Large merges, long branches, high WIP |
| Respect people | Sustainable pace? | Sprint-over-sprint velocity increase |
| Optimize the whole | Local optimization hurting global flow? | One agent's thoroughness bottlenecking others |

---

## System Dynamics Framework (CDR-007)

CDR-007 establishes system dynamics as the first-principle modeling language for process health. Entropy is a derived observation, not a co-equal primitive — always trace it back to the underlying stock, flow, or broken feedback loop.

### Formal Primitives

| Primitive | Definition |
|-----------|-----------|
| **Stock** | An accumulation that changes over time. Measured as a quantity at a point in time (e.g., "14 open retro items"). |
| **Flow** | The rate of change into or out of a stock. Measured as quantity per time period (e.g., "3 items resolved per sprint"). |
| **Reinforcing Loop (R)** | Feedback where a change amplifies itself — virtuous (more → more good) or vicious (more → more bad). |
| **Balancing Loop (B)** | Feedback where a deviation triggers correction back toward equilibrium. |
| **Delay** | A temporal gap between cause and effect that can cause oscillation or overshoot. |

### Named Feedback Loops in DDE

#### Reinforcing Loops

| Loop | Name | Mechanism |
|------|------|-----------|
| **R1** | Test Confidence | More tests → higher confidence → faster builds → more investment in tests |
| **R2** | Retro Neglect | Skipped retro items → accumulation → overwhelm → more skipping |
| **R3** | Spec Quality | Good specs → fewer build defects → faster cycles → more spec investment |

#### Balancing Loops

| Loop | Name | Mechanism |
|------|------|-----------|
| **B1** | Guard Escalation | Violation detected → escalation → attention → resolution → reduced escalation |
| **B2** | Kaizen Resolution | Waste observation → kaizen item → implementation → reduced waste |
| **B3** | Challenge Refinement | Weak challenges → low survival rate → rubric calibration → stronger challenges |

### Entropy as Derived Concept

Entropy — the system state when stocks accumulate without sufficient balancing feedback — is useful shorthand but not a primitive. When you observe entropy, decompose it: which stock is growing? Which outflow is stalled? Which balancing loop has stopped firing? The decomposition reveals the intervention point; "entropy" alone does not.

### Signal-to-Dynamics Mapping

Existing DDE health signals map to dynamics concepts:

| Signal | Dynamics Interpretation |
|--------|------------------------|
| `plan_stale` | Stock (staleness) growing, flow (plan updates) stalled |
| `gate_failed` | Balancing loop interrupted before completion |
| `test_passed` | Reinforcing loop R1 advancing |
| `inscriptions_high` | Stock (TODO annotations) growing, outflow (resolution) insufficient |

### Guidance for New Health Signals

When proposing a new health signal, express it as: "This signal detects [stock/flow/loop condition] in the [named loop or stock]." If you cannot express the signal in dynamics terms, it may be measuring noise rather than a systemic condition.

---

## Sprint Health Briefing Template

```
## Sprint Health Briefing -- Sprint {N}

### Active Andon Alerts
{List or "None"}

### Process Metrics (Last Sprint)
| Metric | Value | Control Status | Trend |
|---|---|---|---|
| Cycle time | {N} days | {Within limits / Special cause / Insufficient data} | {Improving / Stable / Degrading} |
| Throughput | {N} items | ... | ... |
| Rework rate | {N}% | ... | ... |
| Test pass rate | {N}% | ... | ... |

### Unresolved Retro Action Items
| ID | Action | From Sprint | Age | Status |
|---|---|---|---|---|
| AI-{N} | {description} | {sprint} | {N} | Open / Deferred |

### Top Waste Findings
1. {Waste type}: {description} -- {severity}

### Bottleneck Analysis
- **Current constraint:** {stage} -- {evidence}
- **Recommendation:** {exploit / subordinate / elevate}

### Carry-Forward Items
| Item | Original Sprint | Age | Escalation Level | Action |
|------|----------------|-----|-----------------|--------|
| {item} | Sprint {N} | {age} | Warning / Blocking / Critical | {action} |

### Active PDCA Cycles
| ID | Title | Phase | Target Metric |
|---|---|---|---|

### Kaizen Backlog -- Top 3 Ready
1. K-{N}: {description} -- Impact: {H/M/L}, Effort: {S/M/L}

### Process Memory Highlights
- {Key observations relevant to upcoming sprint}

### Stability Check
- **Goal stability:** {stable | drifting}
- **Process changes last sprint:** {count} -- tampering risk: {low | medium | high}
```

---

## Agent Definition Audit (Periodic)

**Trigger:** Every 3 sprints or after significant process changes.

**Protocol:**
1. Inventory all agent files — line count, last modified
2. Path reference check — verify referenced paths exist
3. Collaboration consistency — verify both sides of co-spawn triggers
4. Enforcement registry alignment — compare with _patterns.md
5. Feedback loop wiring — verify producer/consumer sections
6. Template reference check — verify templates exist
7. Scope boundary check — verify paths reflect project structure

Output: Agent Training Audit Report (see `docs/development/AGENT_TRAINING_AUDIT_TEMPLATE.md`)
