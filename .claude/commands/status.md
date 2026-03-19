---
name: status
description: Show project phase status, challenge gate state, and process health by inferring from filesystem artifacts.
user-invocable: true
disable-model-invocation: false
---

## Status Command

Scan the project filesystem to determine the current state of the DDE workflow. Report phase progress, challenge gate status, and process health indicators.

### Phase Detection Rules

Scan for artifacts to determine which phases are complete:

| Phase | Detection | Artifact Path |
|---|---|---|
| **Vision** | File exists with content | `docs/planning/VISION*.md` |
| **Concept** | File exists with content | `docs/planning/CONCEPT*.md` |
| **Blueprint** | Blueprint exists AND ≥1 ADR | `docs/architecture/SOLUTION_BLUEPRINT*.md` + `docs/architecture/ADR-*.md` |
| **Specification** | ≥1 spec with AC section | `docs/specs/SPEC-*.md` |
| **Build** | Implementation files exist | `src/` has non-config files |
| **Verify** | Test files matching specs exist | `tests/` has test files |

### Challenge Gate Detection

Check `docs/planning/CHALLENGE_ARTIFACTS.md` for challenge records referencing each phase:
- Vision gate: Challenge references Vision artifacts
- Concept gate: Challenge references Concept artifacts
- Blueprint gate: Challenge references Blueprint artifacts

### Process Health (IE Agent Data)

If IE agent artifacts exist, include:
- Unresolved retro action items (from `docs/planning/retrospectives/` or `.kit-dev/retrospectives/`)
- Top kaizen backlog items (from `KAIZEN_BACKLOG.md`)
- Process memory highlights (from `IE_PROCESS_MEMORY.md`)

### Session Mode Detection

- If `.kit-dev/DELIVERY_PLAN.md` has active sprint data → Kit Improvement mode likely
- If `docs/planning/DELIVERY_PLAN.md` has active sprint data → Project Build mode likely

### Output Format

```
The Story So Far
================

Session Mode: {Kit Improvement | Project Build | Unknown — ask user}

Vision:        {Complete | In Progress | Not yet begun}
               {artifact path if exists}
               {Challenge gate: Complete | Pending | N/A}

Concept:       {Complete | In Progress | Not yet begun}
               {artifact path if exists}
               {Challenge gate: Complete | Pending | N/A}

Blueprint:     {Complete | In Progress | Not yet begun}
               {artifact path if exists}
               {Challenge gate: Complete | Pending | N/A}

Specification: {N specs found}
               {list spec IDs and titles}

Build:         {In Progress | Not yet begun}
               {summary of src/ contents if present}

Verify:        {In Progress | Not yet begun}
               {test count if available}

---
Process Health
--------------
Unresolved retro items: {count}
Top kaizen item: {K-NNN: description}
Last sprint: {sprint name/number}
Decisions pending: {count, if trackable}
```

### Instructions

1. Use Glob and Read tools to scan for phase artifacts
2. Determine which phases are complete based on artifact existence and content
3. Check for challenge gate completion in CHALLENGE_ARTIFACTS.md
4. If IE agent artifacts exist (KAIZEN_BACKLOG.md, IE_PROCESS_MEMORY.md), include process health section
5. If session logs exist (`.dde/sessions/`), include a brief "story so far" narrative
6. Present the status in the format above, adapting the narrative tone to be informative but not clinical
