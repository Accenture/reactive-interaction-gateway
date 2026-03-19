# Reconnaissance in Force — Exploration Spike

Send 2-3 agents to probe different areas of an unknown problem space simultaneously. The goal is understanding, not solving — map the terrain before committing to a direction.

## When to Invoke

The user says something like:
- "I don't understand this codebase"
- "What are we dealing with here?"
- "Let's explore before we commit"
- "I need a recon on this"
- "Map this out for me"

Or you detect these conditions:
- Entering an unfamiliar codebase or domain
- Problem scope is unclear — you don't know what you don't know
- Multiple possible root causes and you need to narrow the field
- Pre-Schwerpunkt assessment: need to determine whether concentration is even warranted

## Execution Protocol

### Step 1: Define Exploration Scope

Confirm with the user:
- **What are we trying to understand?** (One sentence purpose)
- **What areas should we probe?** (2-3 areas to explore in parallel)
- **What would a useful answer look like?** (What decisions does this inform?)

### Step 2: Assign Scouts

Select 2-3 agents based on the areas to explore. Any agent can be a scout — choose based on the terrain:

| Terrain Type | Good Scout Choices |
|-------------|-------------------|
| Codebase structure | Architect + Backend |
| Test coverage gaps | QE + Semantic |
| Integration boundaries | Integration + Architect |
| Design system / UX patterns | CX Designer + Frontend |
| Infrastructure topology | DevOps + Backend |
| Spec-code alignment | Semantic + QE |
| Legacy system interface | Integration + Backend |

Each scout receives:
1. The exploration purpose
2. Their assigned area to probe
3. Their skill file
4. Instruction: **"Explore this area and report what you find. Focus on: what is known, what is surprising, and what remains unclear. You are scouting, not solving."**

### Step 3: Collect Reports

Each scout reports:
- **What they found** — concrete findings with evidence (file paths, code references)
- **What surprised them** — things that didn't match expectations
- **What remains unclear** — questions that need deeper investigation

### Step 4: Synthesize Terrain Map

Combine scout reports into a Terrain Map:

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
{One of:}
- Coup de Main: Problem is clear, assign to {agent} to solve
- Schwerpunkt: Problem is complex and cross-domain, concentrate with {proposed roster}
- Another Recon pass: Need more data on {specific area}
- No action needed: The terrain is mapped and no problem exists
```

### Step 5: Present and Decide

Present the Terrain Map to the user. Follow Decision Presentation Protocol — one recommendation at a time.

## Key Principles

- **Speed over depth.** Recon is a quick probe, not a deep dive. Each scout should spend minutes, not hours. If you need depth, that's what Schwerpunkt is for.
- **Independence.** Scouts don't coordinate during exploration. Each probes their own area and reports back.
- **Findings, not solutions.** Scouts report what they see, not what they'd do about it. Solutions come after the terrain is mapped.
- **Honest uncertainty.** "I don't know" is a valid and valuable finding. Unknown terrain is as important to map as known terrain.

## Anti-Patterns

- **Recon as procrastination.** If you already know the problem, skip Recon and act. Recon is for genuine uncertainty, not for avoiding commitment.
- **Too many scouts.** 2-3 is the sweet spot. More than 3 creates synthesis overhead without proportional information gain.
- **Solving during scouting.** Scouts who start implementing fixes during exploration are no longer scouting. They're committing to a direction before the terrain is mapped.
- **Ignoring surprises.** The "Surprises" section is often the most valuable part of the Terrain Map. Things that don't match expectations are signals.
