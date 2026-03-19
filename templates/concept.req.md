# NewConcept Domain Template: [Concept Name - Core Business Purpose]

<!--
═══════════════════════════════════════════════════════════════════════════
TEMPLATE VERSION DEFINITION (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
TEMPLATE_FILE: template.concept.req.md
TEMPLATE_VERSION: 5.3.0
TEMPLATE_DESCRIPTION: MINOR v5.3 enhancement: Added CROSS-FEATURE INTEGRATION SCENARIOS section after Exploratory Features for explicit integration design between features. Added PROTOTYPE VALIDATION GATE section between Concept Validation and Implementation Strategy to validate architectural assumptions before codification. Addresses integration gaps and unvalidated assumption failures identified in pipeline effectiveness analysis (R1, R6).
═══════════════════════════════════════════════════════════════════════════

TEMPLATE UPDATE INSTRUCTIONS FOR AI (DO NOT INCLUDE IN FINAL DOCUMENTS)
═══════════════════════════════════════════════════════════════════════════
When updating this template, the AI MUST follow these instructions:

1. VERSION INCREMENTATION:
   - Major (x.0.0): Fundamental changes to template structure or execution model
   - Minor (x.y.0): Significant enhancements like new sections or validation requirements
   - Patch (x.y.z): Minor tweaks, typo fixes, or small clarifications
   - ALWAYS increment version when making ANY change
   - UPDATE TEMPLATE_DESCRIPTION to reflect changes

   VERSION 5.3.0 MINOR ENHANCEMENTS:
   - Added CROSS-FEATURE INTEGRATION SCENARIOS section after Exploratory Features
   - Forces concept authors to define end-to-end workflows and feature interaction points
   - Integration scenarios include data flow, error boundaries, and acceptance criteria
   - Added PROTOTYPE VALIDATION GATE section between Concept Validation and Implementation Strategy
   - Mandatory prototype gate for concepts introducing new architectural patterns
   - Prevents building thousands of LOC on unvalidated architectural assumptions
   - Both additions address pipeline effectiveness analysis findings (R1, R6)

   VERSION 5.2.0 MINOR ENHANCEMENTS:
   - Added CONCEPT MOTIVATION & DECISION RATIONALE section after CONCEPT OVERVIEW
   - ADR-inspired structure preserves "why" decisions were made for AI agents
   - Structured tables for alternatives comparison (AI-parseable)
   - Semantic markers (bold keywords) for key-value extraction
   - Checkbox-based assumption tracking for validation gates
   - Addresses context loss during NewConcepts → Implementation lifecycle transitions

   VERSION 5.1.0 MINOR ENHANCEMENTS:
   - Added FILE LOCATION REQUIREMENTS section with archival lifecycle guidance
   - Integrated semantic domain discovery for consistent folder organization
   - Added shorthand notation (<ce_root>, <project_root>) for path references
   - Specified timestamp-based archival pattern (YYYYMMDD-HHMM prefix)
   - Clarified lifecycle flow: NewConcepts → Codification → Implemented archive

   VERSION 5.0.0 MAJOR ENHANCEMENTS:
   - Template instruction separation (maintenance guidance → TEMPLATE-MAINTENANCE.md)
   - Decentralized capability tracking (placeholder IDs only for NewConcepts, no central registry)
   - Version alignment with DDE workflow v5.0

2. TIME REFERENCE REMOVAL:
   - NEVER include time estimates (minutes, hours, days) in any section
   - Use complexity indicators instead: "Simple task", "Complex implementation", "Multiple components"
   - Use dependency counts: "3 files to modify", "5 test cases required", "2 integrations needed"
   - Use completion metrics: "Until all tests pass", "Until build succeeds", "Until validation complete"

3. PRIORITY AND ORDERING:
   - Base ALL priorities on technical build dependencies, NOT business value
   - Sequence features by: "Must complete X before Y can begin"
   - Use dependency-driven language: "Requires foundation components", "Depends on Feature X completion"
   - Avoid value judgments: "Important", "Critical", "High-priority" unless referring to technical blocking

4. TEMPLATE INSTRUCTION HANDLING:
   - These "TEMPLATE UPDATE INSTRUCTIONS" sections are for AI template maintenance only
   - NEVER copy these sections to documents created from templates
   - Only copy content between the template instruction blocks to final documents
   - Remove ALL template instruction comments from generated documents

5. INSTRUCTION PROPAGATION RULES:
   - Template instructions (marked with "DO NOT INCLUDE IN FINAL") stay in templates only
   - Content instructions (for document creation) get copied to generated documents
   - Metadata fields (TEMPLATE_FILE, TEMPLATE_VERSION) get copied for traceability

FAILURE TO FOLLOW THESE RULES WILL RESULT IN CORRUPTED TEMPLATE SYSTEM.
═══════════════════════════════════════════════════════════════════════════

NEWCONCEPT TEMPLATE USAGE INSTRUCTIONS (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
This template is for EXPLORATORY business domain concepts that haven't found
their final domain/namespace home yet.

KEY DIFFERENCES from standard domain template:
1. Uses PLACEHOLDER capability IDs (TEMP-[DOMAIN]-[NAME]-####)
2. SKIPS capability registry registration during concept phase
3. Includes lifecycle status tracking for concept evolution
4. Will be SPLIT/MOVED to proper domain locations during implementation

IMPORTANT LIFECYCLE:
- This document stays in /Documentation/WorkInProgress/NewConcepts/ during exploration
- During implementation, may be split across multiple actual domains
- Final mature documents will use standard domain-template.domain.md
- This original will move to /NewConcepts/Implemented/ with forward references

CAPABILITY ID FORMAT:
- Use: TEMP-[DOMAIN]-[NAME]-[4-random-chars]
- Example: TEMP-ANALYSIS-SIGNALS-a7b3
- DO NOT add to capability-registry.md during NewConcepts phase

TEMPLATE VERSIONING:
When creating documents from this template, ensure:
1. Use the TEMPLATE_FILE and TEMPLATE_VERSION defined above for metadata fields:
   - "Generated From Template" field: [TEMPLATE_FILE] v[TEMPLATE_VERSION]
   - "Template Version" field: [TEMPLATE_VERSION] ([TEMPLATE_DESCRIPTION])
2. Fill in all metadata fields with actual values, not placeholders
═══════════════════════════════════════════════════════════════════════════
-->

**📋 v5.3 TEMPLATE FEATURES**:
- **Template Version**: 5.3.0 (Integration design and prototype validation gates)
- **Cross-Feature Integration Scenarios**: Explicit end-to-end workflow definition between features (NEW)
- **Prototype Validation Gate**: Mandatory architectural assumption validation before codification (NEW)
- **Motivation Section**: ADR-inspired structure preserving "why" decisions were made
- **AI Optimization**: Structured tables, semantic markers, checkbox tracking for AI agent consumption
- **Decentralized Tracking**: Placeholder IDs only (TEMP-[DOMAIN]-[NAME]-####), no central registry
- **Template Instruction Separation**: Maintenance guidance in TEMPLATE-MAINTENANCE.md
- **NewConcepts Lifecycle**: Exploratory phase → Implementation → Mature domain documents
- **File Organization**: Explicit location requirements with archival lifecycle

## **TEMPLATE USAGE**
This template creates exploratory domain concepts using pattern: `[concept-name].concept.req.md`

**Example Usage:**
- File: `ai-trading-signals.concept.req.md`
- Title: `# NewConcept Domain: AI Trading Signals - Intelligent Market Analysis`

## 📍 **FILE LOCATION REQUIREMENTS**

**📂 Path Shorthand Notation**:
- `<ce_root>` = `<project_root>/Documentation/ContextEngineering`
- `<project_root>` = Your project's root directory (e.g., `/path/to/myproject`)

### **Document Creation Location**
**Initial Creation**: `<ce_root>/NewConcepts/<concept-name>.concept.req.md`
- Use kebab-case for filenames (e.g., `ai-trading-signals.concept.req.md`)
- Document remains in NewConcepts/ during exploration and codification phases
- No domain assignment needed at creation time

**Example Creation Path**:
```
Documentation/WorkInProgress/NewConcepts/ai-trading-signals.concept.req.md
```

### **Document Archival Location**
**Archive After Codification**: `<ce_root>/NewConcepts/Implemented/<timestamp>-<concept-name>.concept.req.md`
- **WHEN**: After corresponding spec-formalization.plan completes
- **WITH**: Corresponding spec-formalization.plan file (both archived together)
- **TIMESTAMP FORMAT**: YYYYMMDD-HHMM (e.g., 20251126-1430)
- Include timestamp prefix for traceability and chronological organization

**Example Archive Path**:
```
Documentation/WorkInProgress/NewConcepts/Implemented/20251126-1430-ai-trading-signals.concept.req.md
```

### **Lifecycle Flow**
```
Phase 1: CREATION
  → Create in NewConcepts/ directory
  → Use placeholder IDs (TEMP-[DOMAIN]-[NAME]-####)
  → Document exploration and requirements

Phase 2: CODIFICATION
  → Codification.icp analyzes and specifies implementation
  → Determines final domain placement using semantic discovery
  → Creates domain.req.md and/or digital.req.md in target locations

Phase 3: ARCHIVAL
  → Move concept.req to Implemented/ with timestamp
  → Move spec-formalization.plan to Implemented/ with timestamp
  → Add forward references to resulting domain/digital documents
```

### **Related Document Placement**
**Codification ICP**: `<ce_root>/NewConcepts/<concept-name>.spec-formalization.plan.md`
- Created during Phase 2 (codification)
- Archived to Implemented/ with same timestamp as concept.req

**Domain Requirements**: Determined by semantic domain discovery during codification
- Codification.icp consults semantic domain discovery system
- Placement follows code namespace structure
- Example: `Documentation/Analysis/fractal-analysis.domain.req.md`

**Digital Requirements**: Determined by semantic domain discovery during codification
- Codification.icp determines UI domain placement
- Follows frontend structure alignment
- Example: `Documentation/Digital/trading-dashboard.digital.req.md`

**Integration with Semantic Discovery**:
When spec-formalization.plan runs, it MUST:
1. Call semantic domain discovery to analyze code structure
2. Determine appropriate domain folder for domain.req.md files
3. Ensure consistency with codebase organization
4. Use same logic as semantic reindexing for folder decisions

## **CONCEPT LIFECYCLE STATUS**
**Current Phase**: [ ] Exploring | [ ] Implementing | [ ] Implemented
**Domain Certainty**: [ ] Unknown | [ ] Single Domain | [ ] Multi-Domain
**Implementation ICP**: TBD (will be created when ready to implement)

**Evolution Tracking:**
- **Original Concept**: This document
- **Resulting Documents**: (Populated after implementation)
  - TBD: Will be determined during domain discovery

## **CAPABILITY DEFINITION**
**Placeholder Capability ID**: TEMP-[DOMAIN]-[NAME]-[4chars] (Temporary - do not register)
**Concept Name**: [Human-readable name]
**Domain Type**: Business Logic Domain (Exploratory)
**Potential Deployment**: [Service/Library/Agent/etc. - may change during implementation]

## **CAPABILITY REGISTRY INTERACTION (NewConcepts)**
**IMPORTANT**: NewConcepts use placeholder IDs to avoid registry pollution.

**During NewConcepts Phase:**
1. Generate placeholder ID: TEMP-[DOMAIN]-[NAME]-[4-random-chars]
2. Do NOT add to capability-registry.md
3. Note: Final IDs will be generated during implementation

**After Implementation:**
1. AI will propose final capability IDs and registry entries
2. Human approves domain placement and final IDs
3. Mature documents use standard registry interaction patterns

**Registry Interaction Pattern:**
- **PLACEHOLDER ONLY** during concept phase
- **AVOID REGISTRATION** to prevent cleanup complexity
- **FINAL REGISTRATION** happens during implementation completion

## **CONCEPT OVERVIEW**
[2-3 paragraphs describing the business concept being explored. Focus on the business problem and potential value, but acknowledge this is exploratory and may evolve during implementation.]

**Core Business Purpose:** [Single sentence capturing the essential business value being explored]

**Potential Business Value:**
- [Potential business outcome #1 with estimated impact]
- [Potential business outcome #2 with estimated impact]
- [Potential business outcome #3 with estimated impact]

**Exploration Questions:**
- [Key question #1 about business viability]
- [Key question #2 about technical feasibility]
- [Key question #3 about domain boundaries]

## 📋 **CONCEPT MOTIVATION & DECISION RATIONALE**

**Purpose**: Preserve the "why" behind this concept for AI agents and humans during implementation phases.

**IMPORTANT**: This section captures the creation context and is **immutable** (written once, archived with concept). For decisions made **during** exploration, use the Decision Log in CONCEPT EVOLUTION TRACKING.

### **Context & Problem Statement**
[Describe the problem being solved. What forces created this decision point? What pain points or opportunities motivated this concept?]

**Business Impact**: [Quantifiable business value or pain point being addressed - e.g., "Manual signal identification delays cost $X/month in missed opportunities"]

**Timing**: [Why now? What makes this concept timely? - e.g., "New market volatility patterns emerged post-2024 making rule-based approaches obsolete"]

### **Decision Drivers**
<!-- Key factors that influenced the decision to pursue this concept -->
- **Driver 1**: [Technical/business factor that influenced the decision - e.g., "Non-stationary market data requires adaptive models"]
- **Driver 2**: [Factor with brief explanation - e.g., "Existing manual process cannot scale to microsecond timeframes"]
- **Constraint 1**: [Limitation that restricted options - e.g., "Must integrate with existing Redpanda messaging (no new infrastructure allowed)"]
- **Constraint 2**: [Platform/timeline/regulatory constraint]

### **Alternatives Considered**
<!-- Structured table for AI parsing and human comparison -->
| Alternative Approach | Pros | Cons | Rejection Reason |
|---------------------|------|------|------------------|
| [Approach 1 - e.g., "Rule-based signal detection"] | [Advantages - e.g., "Explainable, deterministic"] | [Disadvantages - e.g., "Cannot adapt to regime shifts"] | [Why not chosen - e.g., "Market non-stationarity requires adaptability"] |
| [Approach 2 - e.g., "Third-party signal API"] | [Advantages - e.g., "Fast to implement"] | [Disadvantages - e.g., "Black box, vendor lock-in, $50k/year"] | [Why not chosen - e.g., "Cost prohibitive, loss of IP"] |
| [Status Quo / Do Nothing] | [What we keep - e.g., "No development cost"] | [What we lose - e.g., "Miss 30% of trading opportunities"] | [Why change needed - e.g., "Competitive disadvantage growing"] |

### **Chosen Approach & Rationale**
**Selected Approach**: [Name of chosen approach - e.g., "ML-based adaptive signal detection with internal development"]

**Why This Approach**:
[Prose explanation: Why this specific approach over alternatives? What makes it optimal given the drivers and constraints? - e.g., "ML approach provides adaptability to regime shifts while maintaining full control of IP and integration patterns. Internal development allows customization to our specific market focus (Fibonacci/Elliott Wave confluence) that third-party solutions don't address."]

**Key Decision Factors**:
- [Factor #1 that made this approach superior - e.g., "Adaptability to non-stationary markets (addresses Driver 1)"]
- [Factor #2 that aligned with business goals - e.g., "IP retention and competitive differentiation (rejects Approach 2)"]
- [Factor #3 - e.g., "Integration with existing Redpanda infrastructure (satisfies Constraint 1)"]

### **Expected Consequences**
<!-- Balanced view of outcomes - critical for AI implementation awareness -->
**Positive Outcomes**:
- ✅ [Benefit #1 expected from this decision - e.g., "30% increase in profitable signal identification"]
- ✅ [Benefit #2 enabling future capabilities - e.g., "Reusable ML pipeline for other pattern recognition features"]
- ✅ [Benefit #3 - e.g., "Full control of signal logic enables rapid iteration"]

**Tradeoffs & Limitations**:
- ⚠️ [Known limitation #1 accepted with this choice - e.g., "6-month development timeline vs. 2-week API integration"]
- ⚠️ [Technical debt #2 incurred - e.g., "Requires ongoing model retraining infrastructure"]
- ⚠️ [Limitation #3 - e.g., "Initial model accuracy may be lower than mature third-party solutions"]

**Risk Mitigation**:
- [How limitation #1 will be addressed - e.g., "Phased rollout: start with single market, expand as confidence grows"]
- [Monitoring approach for potential issues - e.g., "Daily accuracy metrics, fallback to manual signals if < 70% precision"]

### **Constraints & Assumptions**
**Technical Constraints**:
- [Infrastructure limitation - e.g., "Must use Redpanda for event streaming (no Kafka/RabbitMQ)"]
- [Platform limitation - e.g., ".NET 8 runtime, no Python dependencies in production (training offline OK)"]
- [Data constraint - e.g., "Historical data limited to 5 years, may impact model training"]

**Business Constraints**:
- [Timeline constraint - e.g., "Must deliver MVP before Q2 2025 regulatory deadline"]
- [Budget constraint - e.g., "No additional cloud infrastructure costs (use existing Azure credits)"]
- [Resource constraint - e.g., "Single ML engineer available, cannot hire additional headcount"]

**Critical Assumptions** *(must be validated during implementation)*:
- [ ] **Assumption 1**: [What we're assuming - e.g., "Market data latency will remain < 100ms for real-time signal generation"] - *Validation approach*: [How to test - e.g., "Load test with production data volumes during implementation"]
- [ ] **Assumption 2**: [Technical assumption - e.g., "TensorFlow.NET provides sufficient performance for real-time inference"] - *Validation approach*: [How to verify - e.g., "Benchmark prototype with 1M data points/sec throughput requirement"]
- [ ] **Assumption 3**: [Business assumption - e.g., "Traders will adopt ML signals if > 75% accuracy demonstrated"] - *Validation approach*: [How to test - e.g., "User acceptance testing with 3 senior traders before rollout"]

### **Stakeholder Input**
**Business Stakeholder**: [Name/Role - e.g., "John Smith, Head of Trading"] - [Key input provided - e.g., "Confirmed 30% opportunity loss metric, approved 6-month timeline"]
**Technical Stakeholder**: [Name/Role - e.g., "Jane Doe, Chief Architect"] - [Key architectural guidance - e.g., "Mandated Redpanda integration, approved TensorFlow.NET stack"]
**Domain Expert**: [Name/Role if applicable - e.g., "Bob Wilson, Senior Quant Analyst"] - [Domain-specific insights - e.g., "Recommended Fibonacci/Elliott Wave confluence as primary training signal"]

### **Links to Supporting Documentation**
- [Link to research/analysis that informed this decision - e.g., "Market regime analysis: /Documentation/Research/2024-market-volatility-study.md"]
- [Link to competitive analysis - e.g., "Third-party signal API evaluation: /Documentation/Research/signal-provider-comparison.md"]
- [Link to regulatory requirement if applicable - e.g., "SEC algo trading disclosure requirements: /Documentation/Compliance/sec-regulation-xyz.md"]

---

## **CONCEPT BOUNDARIES (Exploratory)**
**IMPORTANT**: These boundaries are preliminary and may change during implementation.

### **Potential Domain Ownership**
**What This Concept Might Own:**
- [Potential business concept #1 and rules]
- [Potential business concept #2 and rules]
- [Potential business process #1]

**What This Concept Likely Does NOT Own:**
- [Business concept clearly owned by existing domain]
- [Process that this concept participates in but doesn't orchestrate]

**Boundary Uncertainty:**
- [Area where domain ownership is unclear]
- [Potential overlap with existing domains that needs resolution]
- [Cross-cutting concerns that may require coordination]

### **Ubiquitous Language (Preliminary)**
**NOTE**: This language may evolve as domain boundaries are discovered.

| Concept Term | Business Definition | Potential Code Representation | Status |
|--------------|-------------------|------------------------------|---------|
| [Core Concept 1] | [Business meaning being explored] | [Potential technical model] | [ ] Confirmed [ ] Evolving |
| [Core Concept 2] | [Business meaning being explored] | [Potential technical model] | [ ] Confirmed [ ] Evolving |

**Language Evolution Notes:**
- [Terms that may conflict with existing domains]
- [Concepts that may need renaming for consistency]
- [Areas where business stakeholder input is needed]

## **POTENTIAL DEPENDENCIES**
<!-- Relationships with existing or other NewConcept capabilities -->

### **Likely Build Dependencies**
| Capability ID | Capability Name | Type | Document | Confidence Level |
|---------------|-----------------|------|----------|------------------|
| [EXISTING-ID] | [Name] | Data/API/Event | [filename.domain.md] | [ ] High [ ] Medium [ ] Low |
| [TEMP-ID] | [NewConcept Name] | API/Event | [newconcept.domain.md] | [ ] High [ ] Medium [ ] Low |

### **Potential Runtime Dependencies**
| Capability ID | Capability Name | Type | Document | Confidence Level |
|---------------|-----------------|------|----------|------------------|
| [EXISTING-ID] | [Name] | API/Event | [filename.digital.md] | [ ] High [ ] Medium [ ] Low |

### **Potential Consumers**
| Capability ID | Capability Name | What They Might Use | Confidence Level |
|---------------|-----------------|-------------------|------------------|
| [EXISTING-ID] | [Name] | [APIs/Events this might provide] | [ ] High [ ] Medium [ ] Low |

## **EXPLORATORY FEATURES**

### **Feature Summary**
| Feature ID | Feature Name | Status | Confidence | Dependencies | Implementation ICP |
|------------|--------------|--------|------------|--------------|-------------------|
| [PLACEHOLDER-ID]-F001 | [Feature Name] | Exploring | [ ] High [ ] Medium [ ] Low | TBD | TBD |
| [PLACEHOLDER-ID]-F002 | [Feature Name] | Exploring | [ ] High [ ] Medium [ ] Low | TBD | TBD |

### **Feature Implementation Overview**
- **Total Features**: [Number] features being explored
- **Confidence Level**: [X] High Confidence, [Y] Medium Confidence, [Z] Low Confidence
- **Domain Uncertainty**: Features may be distributed across multiple domains during implementation
- **Last Updated**: [Date]

### **Feature Detailed Exploration**

#### **Feature: [PLACEHOLDER-ID]-F001**
**Name**: [Exploratory Feature Name]
**Status**: [ ] Exploring | [ ] Validating | [ ] Ready for Implementation
**Confidence Level**: [ ] High | [ ] Medium | [ ] Low
**Domain Assignment**: [ ] Unknown | [ ] Single Domain | [ ] Multi-Domain

**Business Value Hypothesis:**
[Description of potential business value this feature might provide and why it's worth exploring]

**Exploration Questions:**
- [Key question about business need]
- [Key question about technical feasibility]
- [Key question about user adoption]

**Potential Technical Scope:**
[Rough idea of technical work that might be required, acknowledging uncertainty]

**Potential Dependencies:**
- **Internal**: [Other features or concepts this might depend on]
- **External**: [External systems or services that might be needed]

**Domain Model Speculation:**
- **Potential Aggregates**: [Business concepts that might need modeling]
- **Potential Events**: [Business events this feature might publish/consume]
- **Potential Services**: [Cross-aggregate logic that might be needed]

**Risk Assessment:**
- **Technical Risk**: [ ] Low | [ ] Medium | [ ] High - [Risk description]
- **Business Risk**: [ ] Low | [ ] Medium | [ ] High - [Risk description]
- **Integration Risk**: [ ] Low | [ ] Medium | [ ] High - [Risk description]

**Success Criteria (Preliminary):**
- [ ] [Testable criterion #1 that would validate this feature]
- [ ] [Testable criterion #2 that would validate this feature]
- [ ] [Testable criterion #3 that would validate this feature]

**Implementation Notes:**
[Any additional thoughts, constraints, or considerations discovered during exploration]

---

#### **Feature [Next]: [Next Exploratory Feature Name]**
[Same structure repeated for each feature...]

## **CROSS-FEATURE INTEGRATION SCENARIOS**

**Purpose**: Define how features compose into end-to-end workflows. This section prevents the "components pass, integration fails" pattern by making integration an explicit design concern during concept exploration.

**IMPORTANT**: For each pair of features that interact, define the integration scenario. If your concept has N features, you should have at least N-1 integration scenarios (one per feature boundary in the primary workflow). Concepts with fewer than 2 features may skip this section.

**Why This Section Exists**: The pipeline effectiveness analysis found that individually well-specified features (225 passing unit tests) can still fail completely on first real execution (16+ issues) when integration between features is not explicitly designed. Integration is a separate concern from feature specification — it must be somebody's explicit job.

### **Primary End-to-End Workflow**

[Describe the end-to-end workflow that connects features in sequence. Show what calls what, in what order. Use a flow diagram or ordered list.]

```
[Feature A] → [Feature B] → [Feature C] → [Feature D]
     │              │              │              │
     ▼              ▼              ▼              ▼
 [output]      [transform]    [validate]     [persist]
```

**Workflow Description**: [Prose description of the end-to-end flow — what happens from the initial trigger through to the final outcome]

### **Integration Scenarios**

#### **Integration 1: [Feature A] → [Feature B]**
- **Trigger**: [What triggers the integration — e.g., "Feature A completes task processing and emits TaskResult"]
- **Data Contract**: [What data is passed — e.g., "TaskResult object with status, output, metrics"]
- **Happy Path**: [Expected behavior when both features work correctly]
- **Error Boundary**: [What happens when Feature B fails to process Feature A's output — does Feature A retry? Does the system halt? Is the error silent?]
- **Integration Acceptance Criteria**:
  - [ ] [Testable integration criterion #1 — e.g., "Feature A output is consumed by Feature B without transformation"]
  - [ ] [Testable integration criterion #2 — e.g., "Feature B failure propagates error to caller, not swallowed"]

#### **Integration 2: [Feature B] → [Feature C]**
[Same structure repeated for each integration point...]

### **Error Propagation Map**

| Error Origin | Affected Features | Expected Behavior | Silent Failure Risk |
|-------------|-------------------|-------------------|---------------------|
| [Feature A fails] | [Features B, C, D] | [System halts / degrades gracefully / retries] | [ ] Low [ ] Medium [ ] High |
| [Feature B fails] | [Features C, D] | [Expected behavior] | [ ] Low [ ] Medium [ ] High |

### **End-to-End Workflow Acceptance Criteria**
- [ ] Full workflow executes from initial trigger through final outcome with real (not mocked) data
- [ ] All integration points handle errors gracefully without silent failures
- [ ] System state is consistent after complete workflow execution
- [ ] Performance is acceptable across the entire workflow, not just individual features
- [ ] No TODO comments defer integration wiring to a later phase

---

## **CONCEPT VALIDATION APPROACH**

### **Business Validation**
**Stakeholder Validation:**
- [Business stakeholder group to validate need]
- [User group to validate value proposition]
- [Technical stakeholder to validate feasibility]

**Market Validation:**
- [How to validate market need for this concept]
- [Competitive analysis needed]
- [Regulatory considerations]

### **Technical Validation**
**Proof of Concept Approach:**
- [Technical experiments needed to validate feasibility]
- [Integration tests with existing systems]
- [Performance/scalability validation approach]

**Architecture Validation:**
- [How to validate domain boundary decisions]
- [Integration pattern validation]
- [Scalability assumption validation]

## **PROTOTYPE VALIDATION GATE**

**Purpose**: Validate critical architectural assumptions with a minimal prototype BEFORE proceeding to codification. This prevents building thousands of lines of code on unvalidated assumptions.

**Why This Gate Exists**: The pipeline effectiveness analysis found that a 20,608 LOC implementation (225 passing unit tests) failed on its very first real execution because the chosen architectural pattern (MCP server spawning Claude API agents) was never validated with a prototype. A 200-LOC prototype would have revealed the API key dependency and Docker networking issues immediately, saving significant rework.

### **Gate Applicability**
**This gate is MANDATORY when ANY of the following conditions apply:**
- [ ] The concept introduces a new architectural pattern not used elsewhere in the codebase
- [ ] The concept relies on external APIs, services, or runtime environments not yet validated
- [ ] The concept involves a novel integration pattern between systems
- [ ] The chosen approach was selected over alternatives with significant uncertainty (see Alternatives Considered table)
- [ ] The concept will produce more than 5,000 LOC before first real-world validation

**Gate Status**: [ ] Not Required | [ ] Required — Pending | [ ] Prototype Built | [ ] Validated | [ ] Failed (approach rejected)

### **Prototype Scope**

**Target**: Validate the single riskiest architectural assumption with minimum viable code.

**What to Prototype** (focus on the highest-risk assumption from Critical Assumptions):
- **Assumption Being Validated**: [Reference from Critical Assumptions section — e.g., "Assumption 2: TensorFlow.NET provides sufficient performance"]
- **Minimum Viable Prototype**: [What to build — e.g., "200-LOC script that calls the Claude API and validates response format"]
- **Success Criteria**: [How to know the assumption holds — e.g., "API returns structured response within 2 seconds"]
- **Failure Criteria**: [How to know the assumption is invalid — e.g., "API requires auth mechanism not available in target environment"]
- **Maximum Prototype Effort**: Simple, single-file, throwaway code — no tests, no error handling, no production concerns

### **Prototype Results**

**Status**: [ ] Not Started | [ ] In Progress | [ ] Passed | [ ] Failed
**Date Completed**: [Date]

**Findings**:
- [Key finding #1 from prototype]
- [Key finding #2 from prototype]

**Decision**: [ ] Proceed to codification | [ ] Revise approach (update Chosen Approach & Rationale) | [ ] Explore alternative (add to Alternatives Considered table)

**Evidence**: [Link to prototype code, test results, or screenshots — prototype code may be discarded after validation]

### **Bypass Justification** (if gate marked "Not Required")

If the Prototype Validation Gate is marked "Not Required", document why:
- [Reason #1 — e.g., "All architectural patterns are proven in existing codebase"]
- [Reason #2 — e.g., "This is a standard CRUD feature using established infrastructure"]
- [Reason #3 — e.g., "Similar feature was successfully implemented in [reference] using same approach"]

---

## **IMPLEMENTATION STRATEGY (Preliminary)**

### **Concept-to-Domain Evolution**
**Single Domain Scenario:**
If this concept fits within one domain:
- Move to `/Documentation/[Domain]/[concept-name].domain.md`
- Use standard domain template format
- Register standard capability ID

**Multi-Domain Scenario:**
If this concept spans multiple domains:
- Split into multiple domain documents
- Each gets standard domain template format
- Coordinate integration patterns between domains
- Register multiple capability IDs

**Cross-Cutting Scenario:**
If this concept is truly cross-cutting:
- Consider architectural refactoring
- May require new domain creation
- Extensive integration pattern design

### **Risk Mitigation Strategy**
**High-Risk Elements:**
- [Element #1]: [Mitigation approach]
- [Element #2]: [Mitigation approach]

**Validation Gates:**
- [Gate #1]: [Criteria that must be met before proceeding]
- [Gate #2]: [Criteria that must be met before implementation]

## **SUCCESS MEASUREMENT**

### **Concept Success Criteria**
**Business Success:**
- [Measurable business outcome #1]
- [Measurable business outcome #2]

**Technical Success:**
- [Technical performance criterion #1]
- [Integration success criterion #2]

**User Success:**
- [User adoption criterion #1]
- [User satisfaction criterion #2]

### **Implementation Success Criteria**
**Domain Alignment:**
- [ ] Final domain placement is logical and maintainable
- [ ] Integration patterns are clear and consistent
- [ ] No architectural violations introduced

**Quality Gates:**
- [ ] All features meet acceptance criteria
- [ ] Performance requirements satisfied
- [ ] Security requirements addressed

## **CONCEPT EVOLUTION TRACKING**

### **Decision Log**
**Purpose**: Track decisions made **during** concept exploration (evolutionary decisions).

**Relationship to MOTIVATION Section**: The motivation section captures **why we started** this concept (creation context). This decision log captures **what we decided during exploration** (chronological decisions).

| Date | Decision | Rationale | Impact |
|------|----------|-----------|---------|
| [Date] | [Decision made during exploration - e.g., "Switched from TensorFlow to PyTorch"] | [Why this decision - e.g., "Better .NET integration discovered"] | [What changed - e.g., "Updated Assumption 2 validation"] |

### **Assumption Log**
**Purpose**: Track assumption validation status during exploration and implementation.

| Assumption | Status | Validation Approach | Outcome |
|------------|--------|-------------------|---------|
| [Business assumption] | [ ] Unvalidated [ ] Validating [ ] Validated [ ] Invalidated | [How to test] | [Result] |
| [Technical assumption] | [ ] Unvalidated [ ] Validating [ ] Validated [ ] Invalidated | [How to test] | [Result] |

**Note**: Reference assumptions from MOTIVATION section here and track their validation.

---

**Document Metadata**
- **Concept Name**: [Concept Name]
- **Generated From Template**: [TEMPLATE_FILE] v[TEMPLATE_VERSION]
- **Template Version**: [TEMPLATE_VERSION] ([TEMPLATE_DESCRIPTION])
- **Filename Pattern**: `[concept_name].concept.req.md`
- **Created Date**: [Date]
- **Last Updated**: [Date]
- **Status**: [ ] Exploring | [ ] Validating | [ ] Ready for Implementation | [ ] Implemented
- **Domain Uncertainty**: [ ] High | [ ] Medium | [ ] Low

**Implementation Tracking**
- **Confidence Level**: [X]% Confident in approach
- **Risk Level**: [ ] Low | [ ] Medium | [ ] High
- **Next Steps**: [Description of immediate next actions needed]

**Change History**
| Version | Date | Changes | Author |
|---------|------|---------|---------|
| 1.0 | [Date] | Initial concept exploration | [Author] |

---

**AI Implementation Guidance for NewConcepts**
When implementing concepts from this document:
1. **Extract Motivation Context** - Load the CONCEPT MOTIVATION & DECISION RATIONALE section to understand the "why"
2. **Check Prototype Gate** - Verify the PROTOTYPE VALIDATION GATE status before proceeding to codification. If "Required — Pending", build and validate the prototype first.
3. **Load Integration Scenarios** - Read CROSS-FEATURE INTEGRATION SCENARIOS to understand how features compose. Use these to generate integration verification tasks during codification.
4. **Expect Domain Discovery** - Be prepared to split this across multiple domains
5. **Validate Assumptions** - Test all assumptions from the motivation section during implementation
6. **Maintain Flexibility** - Domain boundaries may shift as understanding improves
7. **Document Evolution** - Track how the concept evolves during implementation
8. **Seek Human Input** - Flag unclear domain boundaries for human decision

**AI Agent Context Loading Pattern** (during implementation phase):
```
Step 1: Read guided-build.plan.md
  → References: "See concept.req TEMP-XXXX-YYYY-#### for motivation"

Step 2: Load archived concept.req from NewConcepts/Implemented/
  → Extract: CONCEPT MOTIVATION & DECISION RATIONALE section

Step 3: Parse motivation section:
  → Decision Drivers → Understand constraints
  → Alternatives Considered (table) → Understand rejected approaches
  → Chosen Approach → Understand rationale
  → Expected Consequences → Understand risks
  → Critical Assumptions (checkboxes) → Validate during implementation

Step 4: Proceed with implementation informed by creation context
```

**Human Review Focus Areas**
- **Business Value**: Does this concept solve a real business problem?
- **Motivation Completeness**: Is the "why" captured sufficiently for future reference?
- **Domain Boundaries**: Are the proposed domain boundaries logical?
- **Technical Feasibility**: Are the technical assumptions realistic?
- **Integration Impact**: How will this affect existing system architecture?
