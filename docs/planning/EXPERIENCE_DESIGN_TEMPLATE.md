---
type: template
name: Experience Design
phase: Experience Design
produces: Experience design document
---

# Experience Design — {FEATURE_NAME}

**Phase:** DDE — Experience Design (Post-Blueprint)
**Status:** Draft
**Date:** {YYYY-MM-DD}
**Led by:** CX Designer
**Co-authored by:** Coherence Architect (Thread Traceability)

**Upstream References:**
- Vision: `{path to Vision document}`
- Concept: `{path to Concept document}`
- Blueprint: `{path to Blueprint document}`

---

## 1. Experience Statement

{One paragraph defining what this feature should FEEL like to use. Not what it does (that's the Concept) or how it's built (that's the Blueprint) — what the experience is. How does the user feel before, during, and after interacting with this feature?}

---

## 2. User Journeys

{Step-by-step interaction flows for each major capability. Describe what happens from the user's perspective — what they see, what they do, what they get back. These are prose narratives, not wireframes.}

### 2.1 {Journey Name}

**Context:** {When and why this journey begins}
**User state:** {What the user knows/expects at this point}

| Step | User Action | System Response | User Sees |
|------|------------|-----------------|-----------|
| 1 | {What the user does} | {What happens} | {What appears — quote actual output if possible} |
| 2 | {Next action} | {Response} | {Output} |

**Feeling at completion:** {What emotional/cognitive state the user is in after this journey}

### 2.2 {Journey Name}

{Repeat for each major journey.}

---

## 3. Voice & Tone

{How does this feature speak? What personality does it project? Include actual text samples the user will encounter.}

### Personality

{2-3 adjectives that define the voice. What it IS and what it is NOT.}

### Register Spectrum

| Context | Register | Example |
|---------|----------|---------|
| {Situation 1} | {Tone description} | {Actual text sample the user would see} |
| {Situation 2} | {Tone description} | {Actual text sample} |

### Sample Output

{Include 2-3 complete examples of actual output the user will see in their terminal or UI. Full text, not summaries.}

```
{Exact output example 1}
```

```
{Exact output example 2}
```

---

## 4. Interaction Patterns

{Key interaction mechanics. How the user engages with this feature moment to moment.}

### 4.1 {Pattern Name}

**Type:** {Command-response / Persistent display / Interactive / Ambient}
**Trigger:** {What initiates this interaction}
**Duration:** {Momentary / Session-length / Persistent}

**Flow:**
```
{User action} → {System response} → {User sees} → {Next action or end}
```

**Progressive Disclosure:** {What's shown by default vs on demand}

### 4.2 {Pattern Name}

{Repeat for each key interaction pattern.}

---

## 5. Accessibility & Degradation

### Terminal Compatibility

| Condition | Behavior |
|-----------|----------|
| NO_COLOR set | {How the feature degrades without color} |
| Terminal < 80 cols | {Layout adaptation} |
| Terminal < 40 cols | {Minimal experience} |
| Screen reader / no visual | {Text-only experience} |

### Accessibility Checklist

- [ ] All information conveyed by color is also conveyed by text/shape
- [ ] Output is meaningful when piped to a file (no ANSI in non-TTY)
- [ ] Interactive elements have keyboard-only access
- [ ] No flashing content (WCAG 2.3.1)
- [ ] {Feature-specific a11y consideration}

### Graceful Degradation

| Missing Dependency | Fallback |
|-------------------|----------|
| {Dependency 1} | {What happens without it} |
| {Dependency 2} | {Fallback behavior} |

---

## 6. Thread Traceability

{Coherence Architect section. How this experience design connects to upstream phase decisions.}

### Vision Threads

| Vision Decision | How This Experience Serves It |
|----------------|-------------------------------|
| {Decision from Vision} | {How the experience design addresses it} |

### Concept Threads

| Concept Capability | Experience Realization |
|-------------------|----------------------|
| {Capability from Concept} | {How the UX realizes this capability} |

### Blueprint Constraints

| Blueprint Decision | Experience Impact |
|-------------------|-------------------|
| {Architecture decision} | {How it constrains or enables the experience} |

### Thread Gaps

{Any threads from upstream phases that this experience design does NOT address, with rationale for why.}

---

## 7. Design Constraints

{Explicit constraints from upstream phases, technical limitations, or user preferences that bound the experience design.}

| Constraint | Source | Impact on Design |
|-----------|--------|-----------------|
| {Constraint} | {Vision / Concept / Blueprint / User feedback} | {How it shapes the experience} |

---

## 8. Open Questions for Specification

1. {Question that the spec phase must resolve}
2. {Another open question}

---

## Next Steps

1. **Contrarian challenge session** — Mandatory challenge gate before proceeding
2. **Skeletal specifications** — Feature-sized specs informed by this experience design
3. **Sprint planning** — Sequence the specs into buildable work items

---

_This is a living document. Update as understanding deepens._
