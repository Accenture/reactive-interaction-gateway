# Elastic Defense — Quality Coalition Assembly

Assemble a coalition of agents to diagnose, contain, and remediate a systemic QUALITY problem that has grown beyond what a single agent can handle.

## When to Invoke

The user says something like:
- "We have a systemic quality problem"
- "Tests are failing across multiple modules"
- "There's drift everywhere"
- "Performance is degrading across the board"
- "We need an elastic defense"

Or you detect one of these triggers:
- Regression cluster: 3+ related test failures across modules
- Spec-code drift cascade: Semantic gap report shows drift in 3+ specs simultaneously
- Performance degradation: Response times or resource usage crossing warning thresholds across services
- Security surface expansion: New vulnerability class affecting multiple components
- Andon escalation: IE andon alert at Critical severity with systemic root cause

## Execution Protocol

### Step 1: Triage

Assess the scope of the problem:
- **How many components are affected?** List them.
- **Is it spreading or contained?** Check recent changes for correlation.
- **What is the blast radius if unaddressed?** Estimate impact.
- **When did it start?** Correlate with recent deployments, merges, or changes.

Produce a triage assessment and determine the coalition roster:

| Problem Type | Lead | Diagnostic Agents | Remediation Agents |
|-------------|------|-------------------|--------------------|
| **Regression cluster** | QE | Architect + Semantic | Backend/Frontend + QE |
| **Spec-code drift cascade** | Semantic | Architect + QE | Product + Backend |
| **Performance degradation** | Backend | Architect + DevOps | Backend + DevOps |
| **Security surface expansion** | DevOps | Architect + Backend + QE | DevOps + Backend + Integration |
| **Post-deploy incident** | DevOps | Backend + QE | DevOps + Backend |

Present triage assessment and proposed roster to user for approval.

### Step 2: Diagnose (Parallel Independent)

Spawn diagnostic agents. Each receives:
1. The triage assessment (scope, affected components, onset timing)
2. Their skill file
3. Relevant context (test results, error logs, git history)
4. Instruction: **"Investigate this problem from your domain perspective. What do you find? What is the root cause from your vantage point? Do NOT coordinate with other agents."**

Anti-anchoring applies — each agent investigates independently.

### Step 3: Root Cause Analysis

Synthesize diagnostic findings:
1. **Primary cause** — the root cause, not just symptoms
2. **Contributing factors** — what made the system vulnerable
3. **Why it wasn't caught earlier** — what detection gap allowed this
4. **Correlation** — do the agents' findings point to the same root cause or different ones?

Present findings to user before proceeding to containment.

### Step 4: Contain

Coordinate immediate containment actions:
- Revert the introducing change if identifiable and safe
- Add temporary guards (feature flags, circuit breakers, rollbacks)
- Prevent spreading to unaffected components
- Each containment action requires user approval for destructive operations

### Step 5: Remediate

Plan and execute the permanent fix:
1. **Fix implementation** — assigned to appropriate remediation agent
2. **Regression test additions** — QE adds tests that would have caught this
3. **Spec updates** — Semantic ensures specs reflect the corrected behavior
4. **Process improvement** — IE observes and updates process memory

### Step 6: Close

Produce the Elastic Defense Report (template in `docs/development/AGENT_TEAMS_GUIDE.md`).

Notify IE agent to:
- Track the event in process memory
- Add kaizen backlog item for systemic prevention
- Flag any process gaps that allowed the problem to develop

## Special Roles

- **IE Agent:** Always observes. Does not participate in diagnosis or remediation. Tracks patterns and process gaps.
- **Contrarian:** Reserve. Not standard assembly. Escalate to Contrarian if root cause reveals an architectural assumption that needs challenging.

## Anti-Patterns

- **Using Elastic Defense for a single test failure.** One failure = one agent fix. Use Elastic Defense only when the problem is systemic (3+ related failures, multiple components).
- **Skipping triage.** Jumping straight to diagnosis without scoping the problem wastes diagnostic effort on the wrong areas.
- **Containing without diagnosing.** A revert that masks the root cause means it will return. Diagnose before you contain (unless the system is actively degrading — then contain first, diagnose second).
- **Remediating without tests.** Every fix must include a regression test. Otherwise the same problem returns next sprint.
- **Ignoring the IE observation.** The IE's process memory update is what prevents recurrence. The fix addresses this instance; the kaizen item addresses the pattern.
