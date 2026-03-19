# Digital Capability Template: [Intent Name - Primary User Goal]

<!--
═══════════════════════════════════════════════════════════════════════════
TEMPLATE VERSION DEFINITION (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
TEMPLATE_FILE: template.digital.req.md
TEMPLATE_VERSION: 5.1.0
TEMPLATE_DESCRIPTION: MINOR v5.1 enhancement: Added explicit FILE LOCATION REQUIREMENTS section with semantic domain discovery integration, namespace alignment guidance for digital/UI requirements, shorthand notation (<ce_root>, <project_root>), and proper placement strategy for frontend documentation aligned with code structure
═══════════════════════════════════════════════════════════════════════════

DOCUMENT CREATION DECISION MATRIX (DO NOT INCLUDE IN FINAL DOCUMENTS)
═══════════════════════════════════════════════════════════════════════════
USE THIS TEMPLATE (template.digital.req.md) WHEN:
✅ Web interfaces, dashboards, or visual components
✅ API endpoints with user-facing responses  
✅ Management consoles or admin interfaces
✅ Developer tools with UI components
❌ DON'T USE for: Backend logic, services, infrastructure (use template.domain.req.md)
❌ DON'T USE for: Simple utilities, generated code, experimental features

Examples: trading-dashboard.digital.req.md, system-admin-console.digital.req.md

FULL-STACK FEATURES: Create BOTH domain.req.md (backend) AND digital.req.md (frontend)
BACKEND-ONLY SYSTEMS: DON'T create digital.req.md (no user interface exists)
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
   - Integrated namespace alignment guidance for digital/UI documentation
   - Added shorthand notation (<ce_root>, <project_root>) for path references
   - Specified placement strategy for NewConcepts-derived vs standard digital docs
   - Clarified semantic domain discovery as authoritative source for folder decisions

   VERSION 5.0.0 MAJOR ENHANCEMENTS:
   - Decentralized capability tracking (capabilities tracked in-document, not central registry)
   - Template instruction separation (maintenance guidance → TEMPLATE-MAINTENANCE.md)
   - Version alignment with DDE workflow v5.0.0
   - Capability/feature tracking section added to template

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

TEMPLATE USAGE INSTRUCTIONS (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
This template defines ONE digital/user-facing capability (deployable artifact).

CAPABILITY ID GENERATION AND REGISTRY:
1. Generate unique ID: [DOMAIN]-[NAME]-[4-random-chars]
   Example: UI-DASHBOARD-f2d1
2. Check /Documentation/ContextEngineering/capability-registry.md for conflicts
3. ADD new capability to registry with:
   - Status: "Not Started"
   - Created Date: Today's date
   - Implementation ICP: "TBD"
   - Document: This file's name

CRITICAL: Digital documents describe USER-FACING capabilities (UI, UX, interactions)
Different from Domain documents which describe BUSINESS capabilities.

FEATURE TRACKING:
- Each feature gets ID: [CAPABILITY-ID]-F[###]
- Track implementation status and ICP references
- Update feature status when ICPs implement them

DEPENDENCIES:
- List other domain/digital capabilities this depends on
- Use capability IDs from the registry
- Specify dependency type (API, Event, UI Component, etc.)

IMPORTANT: This is a specification document. Implementation happens through ICPs.

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
- **Decentralized Capability Tracking**: Capabilities and features tracked in this document (no central registry)
- **Template Instruction Separation**: Maintenance guidance in TEMPLATE-MAINTENANCE.md
- **Semantic Discovery Integration**: File placement aligned with frontend code structure
- **File Organization**: Explicit location requirements with namespace alignment

## **TEMPLATE USAGE**
This template creates digital capability documents using pattern: `[capability-name].digital.md`

**Example Usage:**
- File: `trading-dashboard.digital.md`
- Title: `# Digital Capability: Trading Dashboard - Execute Trades and Monitor Portfolio`

## 📍 **FILE LOCATION REQUIREMENTS**

**📂 Path Shorthand Notation**:
- `<ce_root>` = `<project_root>/Documentation/ContextEngineering`
- `<project_root>` = Your project's root directory (e.g., `/path/to/myproject`)

### **Document Creation Location**

**🤖 PREFERRED: Semantic Domain Discovery (Authoritative)**
When creating digital.req.md from spec-formalization.plan, the ICP MUST:
1. **Call Semantic Domain Discovery System** to analyze frontend code structure
2. **Determine namespace-aligned folder** for this digital document
3. **Use same logic as semantic reindexing** for consistent organization
4. **Validate alignment** with existing frontend namespace patterns

**Semantic Discovery Workflow**:
```
Codification.icp Phase →
  Call semantic domain discovery tool →
    Analyze frontend namespaces and folder structure →
      Determine appropriate digital/UI domain folder →
        Create digital.req.md in discovered location
```

**Standard Namespace-Aligned Pattern**: `<project_root>/Documentation/<DigitalDomain>/<capability-name>.digital.req.md`
- `<DigitalDomain>` folder matches frontend code structure (e.g., Digital, UI, Web, Components)
- Semantic discovery determines exact domain folder based on frontend code analysis
- Ensures documentation mirrors frontend code organization

**Example Creation Paths (Semantic Discovery Results)**:
```
# Digital/UI domain (semantic discovery found Digital namespace for UI features)
Documentation/Digital/trading-dashboard.digital.req.md

# Components domain (semantic discovery found UI components namespace)
Documentation/Digital/chart-library.digital.req.md

# Web domain (semantic discovery found web application namespace)
Documentation/Web/admin-console.digital.req.md
```

**📋 FALLBACK: Manual Namespace Alignment (When Semantic Discovery Unavailable)**
If semantic discovery is not available, follow frontend code namespace manually:
1. Identify primary frontend namespace for this digital capability (e.g., `{PROJECT_NAME}.Web.UI`)
2. Create corresponding folder in Documentation/ (e.g., `Documentation/Digital/` or `Documentation/Web/`)
3. Place digital.req.md in namespace-aligned folder
4. **IMPORTANT**: Update location when semantic discovery becomes available

**Manual Namespace Pattern**: `<project_root>/Documentation/<ManualDigitalDomain>/<capability-name>.digital.req.md`

**Example Manual Placement**:
```
Frontend Code: src/Web/UI/TradingDashboard/
Docs: Documentation/Digital/trading-dashboard.digital.req.md

Frontend Code: src/Components/ChartLibrary/
Docs: Documentation/Digital/chart-library.digital.req.md
```

### **NewConcepts-Derived Digital Documents**

**When Digital.req Created from NewConcepts Codification**:
The spec-formalization.plan process will:
1. Start with concept.req in `<ce_root>/NewConcepts/`
2. Run semantic domain discovery to find proper digital/UI folder
3. Create digital.req.md in discovered location (not in NewConcepts/)
4. Archive original concept.req to `<ce_root>/NewConcepts/Implemented/`
5. Add forward reference from archived concept.req to new digital.req

**Codification Workflow**:
```
NewConcepts/trading-ui.concept.req.md →
  Codification.icp runs →
    Semantic discovery determines "Digital" domain →
      Create: Documentation/Digital/trading-dashboard.digital.req.md
  Archive: NewConcepts/Implemented/20251126-1430-trading-ui.concept.req.md
           (with forward reference to Digital/trading-dashboard.digital.req.md)
```

### **Document Lifecycle (No Archival for Digital Documents)**

Digital.req documents are **long-lived mature documents** and typically:
- ✅ **Remain in place** after creation (stable documentation)
- ✅ **Updated in place** as UI/UX evolves
- ✅ **Version controlled via git** (not filesystem archival)
- ❌ **NOT moved to Implemented/** (unlike concept.req or ICP files)

**Exception - UI Restructuring**:
Only move/archive digital.req if entire UI capability is being retired or merged:
- Create new digital.req in new location
- Add deprecation notice to old digital.req with forward reference
- Archive old digital.req to `Documentation/Archived/<timestamp>-<capability-name>.digital.req.md`

### **Integration with Semantic Discovery**

**CRITICAL: Codification.icp Responsibility**
When spec-formalization.plan creates digital.req files, it MUST:
1. **Call semantic domain discovery API/tool** (not guess folder names)
2. **Use discovered digital/UI folder** for placement
3. **Validate consistency** with frontend code namespace organization
4. **Document discovery decision** (why this folder was chosen)

**Semantic Discovery Ensures**:
- Documentation structure mirrors frontend code structure
- Digital folders align with frontend code namespaces
- Reindexing and documentation use same domain logic
- No manual folder name guessing required

**Tools Available for Discovery**:
- MCP tool: `analyze-domain-map` (identifies domain boundaries)
- MCP tool: `analyze-code-impact` (maps files to business domains)
- Semantic analysis cache (if available)
- Frontend namespace inspection (fallback)

## **CAPABILITY DEFINITION**
**Capability ID**: [DOMAIN-NAME-4chars] (Must be unique - check registry)
**Capability Name**: [Human-readable name]
**Domain Type**: Digital/User-Facing
**Deployment Unit**: [Web App/Mobile App/Component/etc.]

## **CAPABILITY REGISTRY MAINTENANCE**
<!-- CRITICAL: These instructions MUST remain in generated digital documents -->

**Registry Update Requirements:**
When creating this digital document, the AI MUST:

**During Document Creation:**
1. Generate unique capability ID: [DOMAIN]-[NAME]-[4-random-chars]
2. Check `/Documentation/ContextEngineering/capability-registry.md` for conflicts
3. ADD new capability entry to registry with:
   - Status: "Not Started"
   - Created Date: Today's date
   - Implementation ICP: "TBD"
   - Document: This document's filename

**During Feature Updates:**
When ICPs implement features from this digital capability:
1. Update feature status in this document's feature table
2. Update "Implementation ICP" column with actual ICP reference
3. Update "Completed Date" when feature implementation finishes

**Registry Interaction Pattern:**
- **CREATE** new capability entry when this document is first created
- **REFERENCE** this capability ID in all future ICPs and cross-references
- **MAINTAIN** feature status alignment between this document and registry

## **CAPABILITY OVERVIEW**
[2-3 paragraphs describing the digital capability being provided to users and why it's important to the business. Focus on the user problem being solved and the business value created.]

**Primary User Intent:** [Single sentence capturing what the user is trying to accomplish]

**Business Value Delivered:**
- [Specific user outcome #1 with measurable impact]
- [Specific user outcome #2 with measurable impact]  
- [Specific user outcome #3 with measurable impact]

## **CAPABILITY DEPENDENCIES**
<!-- List capabilities this digital capability depends on -->

### **Build Dependencies**
<!-- Must exist before this capability can be built -->
| Capability ID | Capability Name | Type | Document | Why Needed |
|---------------|-----------------|------|----------|------------|
| [CAPABILITY-ID] | [Name] | API/Service | [filename.domain.md] | [Backend data/logic] |

### **Runtime Dependencies**
<!-- Required at runtime but not for build -->
| Capability ID | Capability Name | Type | Document | Why Needed |
|---------------|-----------------|------|----------|------------|
| [CAPABILITY-ID] | [Name] | Event/API | [filename.domain.md] | [Real-time updates] |

### **Consumers**
<!-- Capabilities that depend on this one -->
| Capability ID | Capability Name | What They Use |
|---------------|-----------------|---------------|
| [CAPABILITY-ID] | [Name] | [UI components/patterns this provides] |

## **USER CONTEXT AND MOTIVATION**

### **User Personas and Intent**
**Primary Persona:** [User type and their key characteristics]
- **Goal:** [What they're trying to achieve]
- **Motivation:** [Why they need to accomplish this goal]
- **Context:** [When and where they use this digital capability]
- **Success Criteria:** [How they know they've succeeded]

**Secondary Personas:** [Other user types who may use this capability]
- [Brief description of how their needs differ from primary persona]

### **Capability Triggers and Entry Points**
**Primary Entry Points:**
- [Entry point #1]: [What brings users to this digital capability]
- [Entry point #2]: [Alternative path to access this capability]
- [Entry point #3]: [Another common access point]

**Capability Triggers:**
- [Business event that triggers user need for this capability]
- [External factor that motivates user to access capability]
- [System notification or prompt that initiates capability usage]

## **DIGITAL EXPERIENCE FEATURES**

### **Feature Summary**
| Feature ID | Feature Name | Status | Build Order | Dependencies | Implementation ICP |
|------------|--------------|--------|-------------|--------------|-------------------|
| [CAPABILITY-ID]-F001 | [Feature Name] | Not Implemented | 1 | None | TBD |
| [CAPABILITY-ID]-F002 | [Feature Name] | Not Implemented | 2 | F001 | TBD |

### **Feature Implementation Overview**
- **Total Features**: [Number] features specified
- **Implementation Status**: [X] Not Implemented, [Y] In Progress, [Z] Implemented
- **Build Sequence**: Features organized by technical dependencies, not business priority
- **Last Updated**: [Date]

### **Feature Detailed Specifications**

#### **Feature: [CAPABILITY-ID]-F001**
**Name**: [Experience Feature Name]
**Status**: [ ] Not Implemented | [ ] In Progress | [x] Implemented
**Implementation ICP**: TBD or ICP-IMPL-[###]
**Build Order**: [Number] (dependency sequence)
**Completed Date**: [Date] or "-"

**User Value Provided:**
[Detailed description of what specific value this feature provides to users and how it helps them accomplish their goals]

**User Actions Enabled:**
- [Primary action user can take with this feature]
- [Secondary action available to user]
- [Alternative action for edge cases or different user types]

**Technical Dependencies:**
- **Internal Dependencies**: [Other features that must be completed first]
  - Feature [X]: [Reason for dependency]
  - [UI Component/Service]: [What's needed from this dependency]
- **External Dependencies**: [External systems/services required]
  - [Backend API]: [What data/functionality is needed]
  - [Authentication Service]: [What authentication capabilities required]

**Experience Design Principles:**
- [Key principle #1 governing this feature's design]
- [Key principle #2 ensuring user success]
- [Key principle #3 maintaining consistency]

**Backend Domain Integration:**
- **Domain Services Used:** [Domain capability] for [business function]
- **Data Requirements:** [What information is displayed/collected]
- **Business Rules:** [Business constraints that affect user experience]
- **API Integration:** [Specific endpoints and data contracts needed]

**User Interface Requirements:**
- **Components Needed:** [UI components required for this feature]
- **Interaction Patterns:** [How users interact with this feature]
- **Responsive Design:** [How feature adapts across devices]
- **Accessibility:** [Specific accessibility requirements]

**Quality Requirements:**
- **Performance**: [Response time and interaction requirements]
- **Usability**: [User experience quality requirements]
- **Accessibility**: [Compliance and accommodation requirements]
- **Security**: [User data protection and privacy requirements]

**Acceptance Criteria:**
- [ ] [Specific, testable user scenario #1]
- [ ] [Specific, testable user scenario #2]
- [ ] [Specific, testable user scenario #3]

**Implementation Notes:**
[Any additional UX considerations, technical constraints, or design decisions]

---

#### **Feature [Build Order]: [Next Experience Feature Name]**
[Same structure repeated for each feature...]

## **CAPABILITY FLOW AND ACTIONS**

### **Primary Capability Flow**
**Step 1: [Action Name]**
- **User Goal:** [What user wants to accomplish in this step]
- **Actions Available:** [Specific actions user can take]
- **Information Presented:** [What user sees/learns]
- **Success Criteria:** [How user knows this step succeeded]
- **Next Steps:** [Where user goes from here]

**Step 2: [Action Name]**
- **User Goal:** [What user wants to accomplish in this step]
- **Actions Available:** [Specific actions user can take]
- **Information Presented:** [What user sees/learns]
- **Success Criteria:** [How user knows this step succeeded]
- **Next Steps:** [Where user goes from here]

**Step 3: [Completion Action]**
- **User Goal:** [Final accomplishment]
- **Confirmation:** [How user knows they've succeeded]
- **Next Actions:** [What user typically does after using this capability]

### **Alternative Paths and Edge Cases**
**Alternative Path 1: [Scenario Name]**
- **When This Occurs:** [Conditions that lead to this path]
- **User Experience:** [How the capability flow changes]
- **Recovery Options:** [How user gets back to primary flow or completes goal differently]

**Error Recovery Patterns:**
- **Error Type:** [Common failure point] → **Recovery:** [How user recovers]
- **Error Type:** [System failure scenario] → **Recovery:** [Fallback user experience]

## **USER INTERFACE ARCHITECTURE**

### **Digital Experience Components and Patterns**
**Primary Interface Patterns:**
Each interface pattern serves specific user goals within the digital capability.

- **[Pattern Name]:** Enables [user action] by presenting [information type] in [interaction model]
- **[Pattern Name]:** Supports [user decision] through [interface design] and [guidance approach]

**Shared UI Components:**
Interface components that appear across multiple steps or are reused in other digital capabilities.

- **[Component Name]:** Provides [user capability] with consistent [interaction pattern]
- **[Component Name]:** Displays [information type] using [visualization approach]

### **Responsive and Accessibility Design**
**Multi-Device Experience:**
- **Desktop:** [How experience is optimized for desktop interaction]
- **Mobile:** [How experience adapts for mobile usage]
- **Tablet:** [Specific considerations for tablet interaction]

**Accessibility Requirements:**
- [Accessibility standard compliance]
- [Specific accommodations for user groups]
- [Keyboard navigation patterns]

## **DESIGN REFERENCES**

### **Visual Design Assets**
- **Design System**: [Link to design system documentation]
- **Component Library**: [Link to component library/Storybook]
- **User Flow Designs**: [Figma/design tool links with specific frame references]
- **Prototype Links**: [Interactive prototype links for testing]

### **Specific Component Designs**
| Component Name | Design Reference | Implementation Status | Notes |
|----------------|------------------|---------------------|-------|
| [ComponentName] | [Figma: Flow Name, Frame 12](figma-link) | [ ] Not Implemented | [Design notes] |
| [WidgetName] | [Design System: Widget-v2](link) | [ ] Not Implemented | [Variant info] |

## **INTEGRATION WITH BACKEND CAPABILITIES**

### **Digital Capability Integration**
**User Journey → Domain Logic Mapping:** How user actions translate to business operations.

| User Action | Business Intent | Domain Capability | Integration Pattern | Domain Operation | User Feedback |
|-------------|----------------|-------------------|-------------------|------------------|---------------|
| [User clicks/enters X] | [What user wants to accomplish] | [Domain Name](domain_name.domain.md) | [API/Event/Query] | [Business operation called] | [How user sees result] |
| [User performs Y] | [Business goal] | [Domain Name](domain_name.domain.md) | [API/Event/Query] | [Business operation called] | [User confirmation] |

**DDD Integration Principles for Digital Capabilities:**
- **User Actions → Business Commands**: Every user action should map to a meaningful business operation, not CRUD
- **Domain Events → User Updates**: Business events should translate to relevant user interface updates
- **Business Language in UI**: User interface terms must match domain language (ubiquitous language)
- **Anti-Corruption in UI**: Digital layer translates between user concepts and domain concepts when they differ

### **Real-Time Data Requirements**
**Live Data Needs:**
- [Data type #1]: [Why it needs to be real-time] → [Domain source]
- [Data type #2]: [Business reason for live updates] → [Domain source]

**Event-Driven Updates:**
- **User Action Triggers:** [User action] → [Domain event] → [Experience update]
- **Business Event Updates:** [Domain event] → [User notification/update]

### **Performance and Reliability Requirements**
**Response Time Expectations:**
- [Critical user action]: [Response time requirement] for [user experience reason]
- [Secondary action]: [Response time requirement] for [user experience reason]

**Offline/Degraded Experience:**
- [Fallback experience when systems are unavailable]
- [Cached data strategies for improved performance]

## **AGENT AND AUTOMATION SUPPORT**

### **AI Agent Integration**
**Agent-Assisted Actions:**
- **[Agent Name]:** Helps users [accomplish task] by [providing assistance type]
- **[Agent Name]:** Automates [routine task] when [conditions are met]

**Intelligent Experience Features:**
- **Smart Suggestions:** [How system suggests actions based on user context]
- **Personalization:** [How experience adapts to individual user patterns]
- **Predictive Assistance:** [How system anticipates user needs]

### **Automation Boundaries**
**What Gets Automated:**
- [Task type #1]: [Full automation when conditions are clear]
- [Task type #2]: [Assisted automation with user confirmation]

**What Requires Human Decision:**
- [Decision type #1]: [Why human judgment is required]
- [Decision type #2]: [Business reasons for human involvement]

## **ERROR RECOVERY AND ROLLBACK PROCEDURES**

### **User-Requested Rollback Process**
When a user requests rollback of a completed step or phase:

**Step Rollback Procedure:**
1. **Impact Assessment**:
   - Identify all UI components and user flows modified
   - Check for backend API integration changes
   - Review state management and data flow modifications
   - Assess impact on user experience and existing workflows

2. **Rollback Execution**:
   - Revert all frontend code changes to last stable state
   - Rollback any API integration changes
   - Remove new UI components or restore previous versions
   - Reset user flow configurations to previous state

3. **User Experience Validation**:
   - Test all user scenarios to ensure functionality
   - Verify responsive design still works across devices
   - Confirm accessibility features remain intact
   - Validate integration with backend services

**Phase Rollback Procedure:**
1. **Comprehensive Impact Assessment**:
   - List all user experience features modified in phase
   - Map all UI components and user flows affected
   - Identify all backend integrations impacted
   - Assess user training and documentation changes needed

2. **Rollback Execution**:
   - Revert all frontend changes made during entire phase
   - Restore previous user interface components and flows
   - Rollback API integration and data handling changes
   - Reset user experience configurations and settings

3. **User Experience Validation**:
   - Complete user acceptance testing for all flows
   - Cross-device and cross-browser compatibility testing
   - Accessibility compliance validation
   - Performance testing to ensure no degradation

### **Post-Rollback Requirements**
**Documentation Updates:**
- [ ] All feature statuses updated to reflect rollback
- [ ] User flow documentation reverted to previous state
- [ ] Design system and component library updates reverted
- [ ] User training materials updated if needed

**User Communication:**
- [ ] Users notified of any interface changes due to rollback
- [ ] Support team briefed on reverted functionality
- [ ] User guides and help documentation updated
- [ ] Feedback channels opened for user concerns

## **MEASUREMENT AND OPTIMIZATION**

### **Digital Capability Success Metrics**
**Primary Success Indicators:**
- [Metric #1]: [How it's measured] → [Target value]
- [Metric #2]: [How it's measured] → [Target value]

**User Experience Quality Metrics:**
- **Completion Rate:** [Target percentage] for [capability completion]
- **User Satisfaction:** [Measurement approach] → [Target score]
- **Task Efficiency:** [Time/effort measurement] → [Target improvement]

### **Optimization Opportunities**
**Common Friction Points:**
- [Step where users struggle]: [Improvement opportunity]
- [Information gap]: [Enhancement needed]
- [Decision complexity]: [Simplification approach]

**A/B Testing Opportunities:**
- [Feature variation]: [What to test] for [expected improvement]
- [Experience approach]: [Alternative design] to optimize [user outcome]

## **IMPLEMENTATION GUIDANCE**

### **Digital Experience-First Implementation Approach**
When implementing this digital capability, prioritize user value and experience quality over technical convenience.

**Start With User Research:**
Validate user needs and capability assumptions before building features.

**Build Minimum Viable Experience:**
Focus on core user value in initial implementation, then enhance based on user feedback.

**Design for Accessibility:**
Build accessibility considerations into the foundation rather than adding them later.

**Test with Real Users:**
Continuously validate experience decisions with actual users throughout implementation.

### **Frontend Implementation Strategy**
**Component-Based Architecture:**
Build reusable interface components that can evolve with user needs.

**Progressive Enhancement:**
Ensure core functionality works without JavaScript, then enhance with interactive features.

**Performance Optimization:**
Optimize for user-perceived performance, especially on mobile devices.

### **Implementation Build Sequence**
**Phase 1: Foundation** (Features with no frontend dependencies)
- [ ] **[Basic UI Components]**: [Core interface elements] - Depends on: Design System
- [ ] **[Authentication Flow]**: [User login capability] - Depends on: Backend Auth Service

**Phase 2: Core Experience** (Features building on Phase 1)
- [ ] **[Primary User Action]**: [Main capability] - Depends on: Basic UI, Backend Domain API
- [ ] **[Data Display]**: [Information presentation] - Depends on: Basic UI, Data APIs

**Phase 3: Enhanced Experience** (Features requiring multiple dependencies)
- [ ] **[Advanced Feature]**: [Complex user capability] - Depends on: Primary User Action, Data Display
- [ ] **[Integration Feature]**: [Cross-system capability] - Depends on: External Service API

### **Common Implementation Patterns**
**State Management Pattern:**
```typescript
// Focus on user intent and digital capability state
interface DigitalCapabilityState {
  currentStep: CapabilityStep;
  userContext: UserContext;
  completedActions: CompletedAction[];
  availableNextActions: AvailableAction[];
}
```

**User Action Pattern:**
```typescript
// Actions express user intent, not technical operations
interface UserAction {
  intent: UserIntent;
  context: ActionContext;
  expectedOutcome: ExpectedOutcome;
}
```

## **QUALITY AND GOVERNANCE**

### **User Experience Validation**
**Critical User Experience Requirements:**
- [Requirement #1]: [How this requirement is validated]
- [Requirement #2]: [How this requirement is tested]
- [Requirement #3]: [How this requirement is measured]

**Cross-Capability Consistency:**
- [Consistency requirement #1]: [How consistency is maintained across capabilities]
- [Pattern compliance #1]: [How design patterns are enforced]

### **Experience Quality Gates**
**User Research Validation:**
- [ ] User needs validated through research
- [ ] Capability flow tested with real users
- [ ] Accessibility requirements met

**Technical Quality Validation:**
- [ ] Performance targets met across devices
- [ ] Integration with backend domains functional
- [ ] Error handling provides clear user guidance

### **Business Impact Validation**
**Success Metrics Achievement:**
- [ ] Capability completion rates meet targets
- [ ] User satisfaction scores achieve benchmarks
- [ ] Business value metrics show positive impact

## **EVOLUTION AND MAINTENANCE**

### **Digital Capability Evolution Strategy**
**User Need Changes:**
Plan for how changing user needs will be accommodated through capability evolution.

**Technology Evolution:**
Establish patterns for adopting new interaction technologies while maintaining user familiarity.

**Business Process Changes:**
Design capability to adapt when underlying business processes evolve.

### **Cross-Capability Coordination**
**Capability Handoffs:**
Document how users transition between different digital capabilities and maintain context.

**Shared Experience Patterns:**
Maintain consistency with other capabilities through shared design patterns and components.

### **Continuous Improvement**
**User Feedback Integration:**
Establish regular processes for collecting and acting on user feedback.

**Performance Monitoring:**
Continuously monitor and optimize digital capability performance based on user behavior.

---

**Document Metadata**
- **Digital Capability Name**: [Intent/Capability Name]
- **Generated From Template**: [TEMPLATE_FILE] v[TEMPLATE_VERSION]
- **Template Version**: [TEMPLATE_VERSION] ([TEMPLATE_DESCRIPTION])
- **Filename Pattern**: `[capability_name].digital.md`
- **Created Date**: [Date]
- **Last Updated**: [Date]
- **Status**: [ ] Draft | [ ] Approved | [ ] Active | [ ] Evolving | [ ] Deprecated
- **Related Capabilities**: [List of connected digital capability documents]

**Implementation Tracking**
- **Overall Implementation Status**: [X]% Complete
- **Critical Dependencies**: [List of blocking dependencies]
- **Next Implementation Phase**: [Description of next major implementation milestone]

**Change History**
| Version | Date | Changes | Related ICP |
|---------|------|---------|-------------|
| 1.0 | [Date] | Initial digital capability specification | [ICP Handle] |

---

**AI Implementation Guidance**
When implementing this digital capability:
1. **Follow build sequence** - Implement features in technical dependency order
2. **Establish backend integration first** - Ensure all required APIs and services are available
3. **Build UI components progressively** - Start with basic components, then compose into complex features
4. **Test user scenarios continuously** - Validate user experience at each build phase
5. **Maintain accessibility from foundation** - Build inclusive experiences from the beginning, not as an afterthought

**Human Review Focus Areas**
- **User research accuracy**: Does the capability reflect actual user needs and behaviors?
- **Experience flow**: Are capability steps logical and efficient for users?
- **Integration design**: Do backend integrations support optimal user experiences?
- **Accessibility compliance**: Does the design meet accessibility standards and best practices?