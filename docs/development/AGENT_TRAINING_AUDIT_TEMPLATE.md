---
type: template
name: Agent Training Audit
phase: Sprint Close
produces: IE agent definition audit report
---

# Agent Training Audit — Sprint {N}

**Auditor:** IE Agent
**Date:** {YYYY-MM-DD}
**Trigger:** Periodic (every 3 sprints) | Process change: {description}

---

## Agent File Inventory

| Agent File | Lines | Last Modified | Key Concerns |
|------------|-------|---------------|-------------|
| `_patterns.md` | {N} | {date} | {concerns or "OK"} |
| `product.md` | {N} | {date} | {concerns or "OK"} |
| `architect.md` | {N} | {date} | {concerns or "OK"} |
| `frontend.md` | {N} | {date} | {concerns or "OK"} |
| `backend.md` | {N} | {date} | {concerns or "OK"} |
| `qe.md` | {N} | {date} | {concerns or "OK"} |
| `devops.md` | {N} | {date} | {concerns or "OK"} |
| `cx.md` | {N} | {date} | {concerns or "OK"} |
| `contrarian.md` | {N} | {date} | {concerns or "OK"} |
| `industrial-engineer.md` | {N} | {date} | {concerns or "OK"} |
| `semantic.md` | {N} | {date} | {concerns or "OK"} |
| `integration.md` | {N} | {date} | {concerns or "OK"} |

## Path Reference Check

| Agent | Referenced Path | Exists? | Current? |
|-------|----------------|---------|----------|
| {agent} | {path referenced in agent file} | Yes / No | Yes / Stale |

## Collaboration Consistency

| Agent A | Says co-spawn B for... | Agent B mentions? | Consistent? |
|---------|----------------------|-------------------|-------------|
| {agent} | {trigger description} | Yes / No / Partial | {Yes / No — fix needed} |

## Enforcement Registry Alignment

| Process | Agent File Level | Registry Level | Match? |
|---------|-----------------|----------------|--------|
| {process name} | {level in agent file} | {level in registry} | {Yes / Mismatch} |

## Feedback Loop Wiring

| Loop | Producer Agent Has Section? | Consumer Agent Has Section? | Wired? |
|------|---------------------------|---------------------------|--------|
| QE → Product | {Yes/No} | {Yes/No} | {Yes/No} |
| Semantic → Dev | {Yes/No} | {Yes/No} | {Yes/No} |
| IE → QE | {Yes/No} | {Yes/No} | {Yes/No} |
| Contrarian → All | {Yes/No} | {Yes/No} | {Yes/No} |

## Template Reference Check

| Agent | Referenced Template | Exists? |
|-------|-------------------|---------|
| {agent} | {template path} | Yes / No |

---

## Findings

### P0 — Immediate Fix Required

{Broken references, missing templates, enforcement mismatches that cause agent errors}

### P1 — Next Sprint

{Inconsistent collaboration triggers, stale scope boundaries}

### P2 — Kaizen Backlog

{Agent file bloat, redundant sections, cross-reference opportunities}

## Recommendations

{Prioritized list of fixes with estimated effort}

---

_Audit template version 1.0. Updated by IE agent as audit scope evolves._
