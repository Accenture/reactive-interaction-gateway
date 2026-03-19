# Schwerpunkt — Decisive Multi-Agent Concentration

Concentrate multiple specialist agents at a decisive BUILD problem where getting the answer wrong is expensive and getting it right requires perspectives that no single agent holds.

## When to Invoke

The user says something like:
- "I need a schwerpunkt on this problem"
- "This needs multiple perspectives"
- "I'm stuck on a cross-domain decision"
- "Let's concentrate on this"

Or you detect 2+ of these conditions:
- Cross-domain complexity (spans architecture + performance, UX + data model, etc.)
- High-stakes irreversibility (schema migrations, API contracts, security architecture)
- Solution space ambiguity (multiple viable approaches, team can't converge)
- Historical rework signal (similar past decisions led to rework)
- Blocked progress (single agent can't make headway)

## Execution Protocol

### Step 1: Problem Statement

Confirm the problem statement with the user. One sentence. If it takes a paragraph, the problem isn't focused enough for Schwerpunkt — consider Reconnaissance in Force first.

### Step 2: Classify Problem Type

Determine which standard composition applies:

| Problem Type | Lead | Supporting Agents | Contrarian Role |
|-------------|------|-------------------|-----------------|
| **Architecture** | Architect | Backend + DevOps + Integration | Mandatory (full ICN) |
| **Performance** | Backend | Architect + DevOps + QE | Advisory (Quick Challenge) |
| **Integration** | Integration | Architect + Backend + DevOps | Advisory (Quick Challenge) |
| **UX-Critical** | CX Designer | Product + Frontend | Mandatory (full ICN) |
| **Data Model** | Architect | Backend + Semantic + Product | Mandatory (full ICN) |
| **Security** | DevOps | Backend + Architect + QE | Advisory (Quick Challenge) |

If the problem doesn't fit a standard composition, propose a custom roster. Present to user for approval before proceeding.

### Step 3: Diverge (Parallel Independent Analysis)

Spawn each agent in the roster. Each agent receives:
1. The problem statement
2. Their skill file (`.claude/agents/{role}.md` + `_patterns.md`)
3. Relevant context (specs, code files, architecture docs)
4. Instruction: **"Produce your independent analysis of this problem. Include your recommendation, risks you see, and what you think other perspectives might miss. Do NOT coordinate with other agents."**

Each agent writes their analysis to a clearly labeled section. Anti-anchoring is critical — no agent sees another's output during this phase.

### Step 4: Synthesize

Read all independent analyses. Produce a synthesis:

1. **Convergence points** — Where do all agents agree? (High confidence signals)
2. **Divergence points** — Where do agents disagree? (Present both sides to user)
3. **Unique contributions** — What did one agent see that others missed?
4. **Integrated recommendation** — What approach best synthesizes the strongest elements?

### Step 5: Contrarian Challenge

- For structural problems (Architecture, Data Model, UX-Critical): Run full ICN challenge on the synthesized recommendation. Produce incongruent representations and Light of Ignorance.
- For implementation problems (Performance, Integration, Security): Run Quick Challenge inline.

### Step 6: Present to User

Present to the user:
1. The synthesized recommendation with rationale
2. All individual agent perspectives (full visibility — Visibility Rule)
3. Contrarian challenge findings
4. Divergence points that need a human decision

Follow the Decision Presentation Protocol — one decision at a time if multiple choices emerge.

### Step 7: Record Decision

After user decides:
1. Record the decision, rationale, and dissenting perspectives
2. Write to appropriate artifact (ADR for architecture, spec note for implementation)
3. Note which agents' perspectives were adopted and which were set aside

## Output Format

Use the Schwerpunkt Report template from `docs/development/AGENT_TEAMS_GUIDE.md`.

## Anti-Patterns

- **Over-concentration:** Using Schwerpunkt for a problem one agent can handle. If the problem is clear and within one domain, use Coup de Main instead.
- **Anchoring:** Letting agents see each other's analyses before producing their own. This defeats the entire purpose.
- **Synthesis without visibility:** Presenting only the synthesized recommendation without the individual perspectives. The user must see the full landscape.
- **Skipping the Contrarian:** For structural problems, the Contrarian challenge is mandatory, not optional.
- **Schwerpunkt as delay tactic:** Concentration is for genuinely hard problems, not for avoiding a decision. If the answer is known, just execute.
