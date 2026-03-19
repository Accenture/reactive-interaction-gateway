---
type: template
name: Concept Document
phase: Concept
produces: Project concept document
---

# Concept — reactive-interaction-gateway

**Phase:** DDE Phase 2 — Concept
**Status:** Draft
**Date:** {YYYY-MM-DD}
**Vision:** [VISION.md](VISION.md)

---

## 1. The Nucleus

{One paragraph defining the irreducible core of this project. What is the ONE thing that, if removed, means the project doesn't exist? Everything else serves this nucleus. Be ruthlessly specific.}

---

## 2. Core Capabilities

{N capabilities form the minimum viable product. Each is essential; none can be cut without undermining the nucleus.}

### 2.1 {Capability Name}

{What this capability does and why it's essential to the nucleus.}

**What it does:**
- {Concrete behavior 1}
- {Concrete behavior 2}

**Key interactions:**
| Trigger | Action | Result |
|---------|--------|--------|
| {User does X} | {System does Y} | {Outcome Z} |

### 2.2 {Capability Name}

{Repeat pattern for each core capability.}

---

## 3. User Journey

{Walk through the primary user journey end-to-end. This is the "golden path" — the most important flow that proves the nucleus works.}

### 3.1 {Journey Step 1}

**User intent:** {What the user is trying to accomplish}
**Experience:** {What happens — describe concretely, not abstractly}
**Output:** {What the user has when this step is complete}

### 3.2 {Journey Step 2}

{Repeat for each major step.}

---

## 4. Information Architecture

{How is information organized in the system? What are the key entities/objects and how do they relate?}

| Entity | Description | Relationships |
|--------|-------------|---------------|
| {Entity} | {What it is} | {How it relates to others} |

---

## 5. Key Interactions

{Detail the most important user interactions — the ones that make or break the experience.}

### 5.1 {Interaction Name}

**Context:** {When/why this interaction occurs}
**Flow:**
1. {Step 1}
2. {Step 2}
3. {Step 3}

**Edge cases:**
- {What happens if X}
- {What happens if Y}

---

## 6. Constraints & Trade-offs

{Document the key trade-offs made in this concept. Every "yes" implies a "no."}

| Trade-off | Chose | Over | Rationale |
|-----------|-------|------|-----------|
| {Decision area} | {What we chose} | {What we didn't} | {Why} |

---

## 7. Open Questions for Blueprint Phase

1. {Technical question that Blueprint must resolve}
2. {Architecture question}
3. {Integration question}

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| {Risk} | {H/M/L} | {H/M/L} | {How to address} |

---

## Next Steps

1. **Contrarian challenge session** — Mandatory challenge gate before proceeding
2. **Solution Blueprint** — Architecture design: system structure, key technology decisions, integration points
3. **Initial ADRs** — Key architectural decisions that emerged from this concept

---

_This is a living document. Update as understanding deepens._
