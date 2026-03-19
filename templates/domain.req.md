# Domain Requirements: [Domain Name - Core Business Purpose]

<!--
═══════════════════════════════════════════════════════════════════════════
TEMPLATE VERSION DEFINITION (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
TEMPLATE_FILE: template.domain.req.md
TEMPLATE_VERSION: 5.1.0
TEMPLATE_DESCRIPTION: MINOR v5.1 enhancement: Added explicit FILE LOCATION REQUIREMENTS section with semantic domain discovery integration, namespace alignment guidance, shorthand notation (<ce_root>, <project_root>), and proper placement strategy for both standard and NewConcepts-derived domain documents
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

   VERSION 5.1.0 MINOR ENHANCEMENTS:
   - Added FILE LOCATION REQUIREMENTS section with semantic discovery integration
   - Integrated namespace alignment guidance for consistent code/doc organization
   - Added shorthand notation (<ce_root>, <project_root>) for path references
   - Specified placement strategy for NewConcepts-derived vs standard domain docs
   - Clarified semantic domain discovery as authoritative source for folder decisions

   VERSION 5.0.0 MAJOR ENHANCEMENTS:
   - Template instruction separation (maintenance guidance → TEMPLATE-MAINTENANCE.md)
   - Decentralized capability tracking (in domain.req files, no central registry)
   - Version alignment with DDE workflow v5.0.0

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

DOMAIN TEMPLATE USAGE INSTRUCTIONS (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
This template is for MATURE DOMAIN business requirements in known bounded contexts.

KEY DIFFERENCES from NewConcept template:
1. Uses STANDARD capability IDs ([DOMAIN]-[NAME]-####)
2. Capabilities tracked directly in this document (not central registry)
3. Focused on business logic and domain rules
4. Stays in stable location aligned with code namespace

IMPORTANT PLACEMENT:
- Location determined by semantic domain discovery OR code namespace
- Codification.icp should call semantic discovery to find correct location
- Once placed, document remains stable (not moved during implementation)

CAPABILITY TRACKING:
- NEW capabilities: Add section with ID, status "Not Implemented"
- EXISTING capabilities: Update specification, preserve ID and references

TEMPLATE VERSIONING:
When creating documents from this template, ensure:
1. Use the TEMPLATE_FILE and TEMPLATE_VERSION defined above for metadata fields:
   - "Generated From Template" field: [TEMPLATE_FILE] v[TEMPLATE_VERSION]
   - "Template Version" field: [TEMPLATE_VERSION] ([TEMPLATE_DESCRIPTION])
2. Fill in all metadata fields with actual values, not placeholders
═══════════════════════════════════════════════════════════════════════════
-->

**📋 v5.1 TEMPLATE FEATURES**:
- **Template Version**: 5.1.0 (DDE workflow v5.0 aligned with file organization enhancements)
- **Decentralized Tracking**: Capability tracking in this document (no central registry)
- **Template Instruction Separation**: Maintenance guidance in TEMPLATE-MAINTENANCE.md
- **Semantic Discovery Integration**: File placement aligned with code structure
- **File Organization**: Explicit location requirements with namespace alignment

## **TEMPLATE USAGE**
This template creates mature domain business requirements using pattern: `[domain-name].domain.req.md`

**Example Usage:**
- File: `fractal-analysis.domain.req.md`
- Title: `# Domain Requirements: Fractal Analysis - Technical Market Analysis Domain`

## 📍 **FILE LOCATION REQUIREMENTS**

**📂 Path Shorthand Notation**:
- `<ce_root>` = `<project_root>/Documentation/ContextEngineering`
- `<project_root>` = Your project's root directory (e.g., `/path/to/myproject`)

### **Document Creation Location**

**🤖 PREFERRED: Semantic Domain Discovery (Authoritative)**
When creating domain.req.md from spec-formalization.plan, the ICP MUST:
1. **Call Semantic Domain Discovery System** to analyze code structure
2. **Determine namespace-aligned folder** for this domain document
3. **Use same logic as semantic reindexing** for consistent organization
4. **Validate alignment** with existing code namespace patterns

**Semantic Discovery Workflow**:
```
Codification.icp Phase →
  Call semantic domain discovery tool →
    Analyze code namespaces and folder structure →
      Determine appropriate domain folder →
        Create domain.req.md in discovered location
```

**Standard Namespace-Aligned Pattern**: `<project_root>/Documentation/<Domain>/<domain-name>.domain.req.md`
- `<Domain>` folder matches code namespace (e.g., Analysis, Data, Messaging, Infrastructure)
- Semantic discovery determines exact domain folder based on code analysis
- Ensures documentation mirrors code organization

**Example Creation Paths (Semantic Discovery Results)**:
```
# Analysis domain (semantic discovery found Analysis namespace)
Documentation/Analysis/fractal-analysis.domain.req.md

# Data domain (semantic discovery found Data namespace)
Documentation/Data/price-storage.domain.req.md

# Messaging domain (semantic discovery found Messaging namespace)
Documentation/Messaging/signal-publisher.domain.req.md
```

**📋 FALLBACK: Manual Namespace Alignment (When Semantic Discovery Unavailable)**
If semantic discovery is not available, follow code namespace manually:
1. Identify primary code namespace for this domain (e.g., `{PROJECT_NAME}.Analysis`)
2. Create corresponding folder in Documentation/ (e.g., `Documentation/Analysis/`)
3. Place domain.req.md in namespace-aligned folder
4. **IMPORTANT**: Update location when semantic discovery becomes available

**Manual Namespace Pattern**: `<project_root>/Documentation/<ManualDomain>/<domain-name>.domain.req.md`

**Example Manual Placement**:
```
Code: src/{PROJECT_NAME}.Analysis/FractalAnalysis/
Docs: Documentation/Analysis/fractal-analysis.domain.req.md

Code: src/{PROJECT_NAME}.Data/PriceStorage/
Docs: Documentation/Data/price-storage.domain.req.md
```

### **NewConcepts-Derived Domain Documents**

**When Domain.req Created from NewConcepts Codification**:
The spec-formalization.plan process will:
1. Start with concept.req in `<ce_root>/NewConcepts/`
2. Run semantic domain discovery to find proper domain folder
3. Create domain.req.md in discovered location (not in NewConcepts/)
4. Archive original concept.req to `<ce_root>/NewConcepts/Implemented/`
5. Add forward reference from archived concept.req to new domain.req

**Codification Workflow**:
```
NewConcepts/ai-signals.concept.req.md →
  Codification.icp runs →
    Semantic discovery determines "Analysis" domain →
      Create: Documentation/Analysis/ai-signals.domain.req.md
  Archive: NewConcepts/Implemented/20251126-1430-ai-signals.concept.req.md
           (with forward reference to Analysis/ai-signals.domain.req.md)
```

### **Document Lifecycle (No Archival for Domain Documents)**

Domain.req documents are **long-lived mature documents** and typically:
- ✅ **Remain in place** after creation (stable documentation)
- ✅ **Updated in place** as domain evolves
- ✅ **Version controlled via git** (not filesystem archival)
- ❌ **NOT moved to Implemented/** (unlike concept.req or ICP files)

**Exception - Domain Restructuring**:
Only move/archive domain.req if domain itself is being retired or merged:
- Create new domain.req in new location
- Add deprecation notice to old domain.req with forward reference
- Archive old domain.req to `Documentation/Archived/<timestamp>-<domain-name>.domain.req.md`

### **Integration with Semantic Discovery**

**CRITICAL: Codification.icp Responsibility**
When spec-formalization.plan creates domain.req files, it MUST:
1. **Call semantic domain discovery API/tool** (not guess folder names)
2. **Use discovered domain folder** for placement
3. **Validate consistency** with code namespace organization
4. **Document discovery decision** (why this folder was chosen)

**Semantic Discovery Ensures**:
- Documentation structure mirrors code structure
- Domain folders align with code namespaces
- Reindexing and documentation use same domain logic
- No manual folder name guessing required

**Tools Available for Discovery**:
- MCP tool: `analyze-domain-map` (identifies domain boundaries)
- MCP tool: `analyze-code-impact` (maps files to business domains)
- Semantic analysis cache (if available)
- Code namespace inspection (fallback)

## **DOMAIN OVERVIEW**
[Single-sentence description of the business domain's core responsibility within the broader system]

**Business Context**: [2-3 paragraphs explaining the business purpose of this domain, its significance within the organization, and the business problems it solves]

**Domain Boundaries:**
- **In Scope**: [Clear definition of what business capabilities belong to this domain]
- **Out of Scope**: [Clear definition of what this domain does NOT handle]
- **Bounded Context**: [How this domain's language and concepts differ from or align with other domains]

## **UBIQUITOUS LANGUAGE**

### **Core Business Concepts**
| Concept | Business Definition | Technical Representation | Status |
|---------|---------------------|--------------------------|--------|
| [Business Term] | [Clear business meaning] | [How modeled in code] | [ ] Defined [ ] Evolving |

### **Domain-Specific Terminology**
- **[Term]**: [Business definition with context and usage examples]
- **[Term]**: [Business definition with context and usage examples]

### **Language Governance**
**Prohibited Terms** (conflicts with other domains):
- [Term]: Use [preferred term] instead - [reason for prohibition]

**Preferred Synonyms** (consistency across documentation):
- [Technical term]: Use [business term] in domain documents
- [Ambiguous term]: Use [specific term] for clarity

## **BUSINESS RULES**

### **Invariants** (Rules That Must Always Be True)
| Rule ID | Business Rule | Enforcement | Status |
|---------|---------------|-------------|--------|
| [DOMAIN]-BR-001 | [Business rule statement] | [Where/how enforced] | [ ] Not Implemented [ ] Implemented |

### **Business Logic** (Operational Rules)
| Rule ID | Business Logic | Dependencies | Status |
|---------|---------------|--------------|--------|
| [DOMAIN]-BL-001 | [Business logic description] | [Required data/services] | [ ] Not Implemented [ ] Implemented |

## **CAPABILITY TRACKING (Decentralized)**

**IMPORTANT**: This document tracks capabilities for this domain only. No central registry.

### **Capabilities Defined in This Domain**

#### **Capability: [Capability Name]**
**Capability ID**: [DOMAIN]-[NAME]-[4chars] (e.g., ANALYSIS-FRACTAL-a7b3)
**Status**: [ ] Not Implemented | [ ] In Progress | [x] Implemented
**Implementation ICP**: [ICP-Handle] or "TBD"
**Created Date**: [Date]
**Completed Date**: [Date] or "-"

**Business Purpose:**
[Clear description of business capability this provides]

**Technical Scope:**
- **Aggregates**: [Aggregate roots this capability uses]
- **Services**: [Domain services involved]
- **Events**: [Domain events published/consumed]

**Integration Points:**
- **Consumed By**: [Other capabilities that use this]
- **Depends On**: [Capabilities this requires]

**Specifications:**
- [ ] [Specific requirement #1]
- [ ] [Specific requirement #2]

---

#### **Capability: [Next Capability Name]**
[Same structure repeated...]

## **DOMAIN FEATURES**

### **Feature Summary**
| Feature ID | Feature Name | Status | Dependencies | Implementation ICP |
|------------|--------------|--------|--------------|-------------------|
| [DOMAIN]-F001 | [Feature Name] | [ ] Not Implemented [ ] Implemented | [Dependencies] | [ICP-Handle] |

### **Feature Implementation Overview**
- **Total Features**: [Number] features specified
- **Implementation Status**: [X] Not Implemented, [Y] In Progress, [Z] Implemented
- **Build Sequence**: Features organized by technical dependencies, not business priority
- **Last Updated**: [Date]

### **Feature Detailed Specifications**

#### **Feature [Build Order]: [Feature Name]**
**Implementation Status**: [ ] Not Implemented | [ ] In Progress | [x] Implemented
**Implementation ICP**: [ICP-Handle] or "Pending"
**Completed Date**: [Date] or "-"

**Business Description:**
[Detailed description of what business capability this feature provides and why it's valuable]

**Technical Scope:**
[Specific technical work required to implement this feature]

**Technical Dependencies:**
- **Internal Dependencies**: [Other features that must be completed first]
  - Feature [X]: [Reason for dependency]
- **External Dependencies**: [External systems/services required]
  - [External API/Service]: [What's needed]

**Integration Requirements:**
- **Data Integration**: [Data sources, schemas, persistence]
- **API Integration**: [External APIs consumed or endpoints exposed]
- **Event Integration**: [Events published or consumed]
- **UI Integration**: [Frontend components or user interface requirements]

**Quality Requirements:**
- **Performance**: [Response time, throughput, scalability]
- **Security**: [Authentication, authorization, data protection]
- **Reliability**: [Uptime, error handling, recovery]

**Acceptance Criteria:**
- [ ] [Specific, testable criterion #1]
- [ ] [Specific, testable criterion #2]

**Implementation Notes:**
[Any additional implementation guidance]

---

#### **Feature [Next]: [Next Feature Name]**
[Same structure repeated...]

## **DOMAIN MODEL**

### **Aggregate Roots**
```csharp
// IMPLEMENTATION STATUS: Not Implemented
// IMPLEMENTING ICP: [ICP-Handle]
public class [AggregateRoot] : AggregateRoot<[AggregateRoot]Id>
{
    // Business rules enforced by this aggregate
    // Invariants that must always hold true
    // Domain events published by this aggregate
}
```

### **Entities and Value Objects**
```csharp
// Supporting entities with detailed specifications
public class [Entity] : Entity<[Entity]Id>
{
    // IMPLEMENTATION STATUS: Not Implemented
    // IMPLEMENTING ICP: [ICP-Handle]
}

// Value objects with validation
public record [ValueObject]([Type] Value)
{
    // IMPLEMENTATION STATUS: Not Implemented
    // Validation rules and behavior
}
```

### **Domain Services**
```csharp
// IMPLEMENTATION STATUS: Not Implemented
// IMPLEMENTING ICP: [ICP-Handle]
public class [DomainService] : IDomainService
{
    // Cross-aggregate business logic
    // Complex validations and orchestrations
}
```

## **INTEGRATION POINTS**

### **Domain Events Published**
| Event Name | Business Trigger | Payload | Consumers |
|------------|-----------------|---------|-----------|
| [EventName] | [When published] | [Data included] | [Who consumes] |

### **Domain Events Consumed**
| Event Name | Source Domain | Business Response | Document |
|------------|---------------|------------------|----------|
| [EventName] | [Source] | [What this domain does] | [filename.domain.md] |

### **API Contracts**
**Commands Accepted:**
- `[CommandName]`: [Business operation this represents]

**Queries Supported:**
- `[QueryName]`: [Business question this answers]

### **Data Dependencies**
**Data This Domain Owns:**
- [Data concept]: [Tables/stores/schemas owned]

**Data This Domain Reads:**
- [Data concept]: [Source domain and access pattern]

## **IMPLEMENTATION NOTES**

### **Architecture Patterns**
- **Aggregate Design**: [How aggregates are structured in this domain]
- **Event Sourcing**: [ ] Enabled [ ] Not Used
- **CQRS**: [ ] Enabled [ ] Not Used

### **Technical Constraints**
- [Constraint #1]: [Business/technical reason]
- [Constraint #2]: [Business/technical reason]

---

**Document Metadata**
- **Domain Name**: [Domain Name]
- **Generated From Template**: [TEMPLATE_FILE] v[TEMPLATE_VERSION]
- **Template Version**: [TEMPLATE_VERSION] ([TEMPLATE_DESCRIPTION])
- **Created Date**: [Date]
- **Last Updated**: [Date]
- **Status**: [ ] Draft | [ ] Review | [ ] Approved | [ ] Active | [ ] Evolving
- **Related Domains**: [List of related domain documents]

**Implementation Tracking**
- **Overall Implementation Status**: [X]% Complete
- **Critical Dependencies**: [List of blocking dependencies]
- **Next Implementation Milestone**: [Description]

**Change History**
| Version | Date | Changes | Related ICP |
|---------|------|---------|-------------|
| 1.0 | [Date] | Initial domain requirements | [Concept ICP Handle] |
| [Version] | [Date] | [Description of changes] | [Related ICP Handle] |

---

**AI Implementation Guidance**
When implementing this domain:
1. **Follow DDD Principles** - Maintain aggregate boundaries and invariants
2. **Enforce Business Rules** - All business rules must be validated
3. **Publish Domain Events** - Ensure loose coupling with other domains
4. **Maintain Bounded Context** - Use domain-specific language consistently
5. **Preserve Domain Boundaries** - Don't mix concerns from other domains

**Human Review Focus Areas**
- **Business accuracy**: Do specifications correctly represent business needs?
- **Domain boundaries**: Are the bounded context boundaries logical and maintainable?
- **Integration coherence**: Do cross-domain integrations make business sense?
- **Completeness**: Are all necessary business rules and capabilities documented?
