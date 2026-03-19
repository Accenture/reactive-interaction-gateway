# Issue: [Issue Title - Brief Description]

<!--
═══════════════════════════════════════════════════════════════════════════
TEMPLATE VERSION DEFINITION (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
TEMPLATE_FILE: template.issue.req.md
TEMPLATE_VERSION: 1.0.0
TEMPLATE_DESCRIPTION: Initial v1.0 release: Structured template for capturing defects and enhancements with provenance metadata, root cause analysis placeholders, and resolution approach documentation. Supports lightweight 3-phase resolution workflow via template.issue-fix.plan integration.
═══════════════════════════════════════════════════════════════════════════

TEMPLATE UPDATE INSTRUCTIONS FOR AI (DO NOT INCLUDE IN FINAL DOCUMENTS)
═══════════════════════════════════════════════════════════════════════════
When updating this template, the AI MUST follow these instructions:

1. VERSION INCREMENTATION:
   - Major (x.0.0): Fundamental changes to YAML schema or section structure
   - Minor (x.y.0): Significant enhancements like new sections or metadata fields
   - Patch (x.y.z): Minor tweaks, typo fixes, or small clarifications
   - ALWAYS increment version when making ANY change
   - UPDATE TEMPLATE_DESCRIPTION to reflect changes

   VERSION 1.0.0 INITIAL RELEASE:
   - YAML frontmatter schema with provenance fields (discovered_during, discovery_context, discovered_by, discovery_timestamp)
   - Issue classification fields (issue_type, severity, status)
   - Nested issue support (nested_from, resolution_depth)
   - Section structure: Issue Description, Root Cause Analysis, Resolution Approach, Additional Context
   - Integration with template.issue-fix.plan for autonomous resolution workflow

2. YAML SCHEMA BACKWARD COMPATIBILITY:
   - Existing issue.req files (ISSUE-002 through ISSUE-023) must remain valid
   - New fields should be OPTIONAL unless explicitly required for new workflows
   - Required fields: issue_type, severity, status
   - Optional fields: All provenance fields (for manual issues)

3. TEMPLATE INSTRUCTION HANDLING:
   - These "TEMPLATE UPDATE INSTRUCTIONS" sections are for AI template maintenance only
   - NEVER copy these sections to documents created from templates
   - Only copy content between the template instruction blocks to final documents
   - Remove ALL template instruction comments from generated documents

4. INSTRUCTION PROPAGATION RULES:
   - Template instructions (marked with "DO NOT INCLUDE IN FINAL") stay in templates only
   - Content instructions (for document creation) get copied to generated documents
   - Metadata fields (TEMPLATE_FILE, TEMPLATE_VERSION) get copied for traceability

FAILURE TO FOLLOW THESE RULES WILL RESULT IN CORRUPTED TEMPLATE SYSTEM.
═══════════════════════════════════════════════════════════════════════════

ISSUE.REQ TEMPLATE USAGE INSTRUCTIONS (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
This template is for capturing defects (broken behavior) and enhancements
(missing capabilities) discovered during discovery activities.

KEY DIFFERENCES from concept.req template:
1. Lightweight scope: < 4 hours effort, 1-5 files, single domain
2. Provenance tracking: Links to execution context where issue was discovered
3. 3-phase resolution: Use template.issue-fix.plan instead of full codification
4. File organization: Active/ -> Resolved/ (with timestamp archival)

WHEN TO USE ISSUE.REQ vs CONCEPT.REQ:
- Issue.req: < 4 hours, 1-5 files, single domain (localized fix/enhancement)
- Concept.req: > 4 hours, 6+ files, multi-domain (new feature/system change)

LIFECYCLE:
- Created in: Documentation/WorkInProgress/Issues/Active/
- Naming: ISSUE-NNN-description.issue.req.md
- Resolution: template.issue-fix.plan executes 3-phase TDD workflow
- Archived to: Documentation/WorkInProgress/Issues/Resolved/ (with timestamp)
- Format: YYYYMMDD-HHMM-ISSUE-NNN-description.issue.req.md

NESTED ISSUES:
- Max resolution depth: 1 (original issue can spawn 1 nested child only)
- If nested child discovers another issue, defer to Active/ as new standalone issue
- Use nested_from field to link nested issue to parent
- Set resolution_depth = 1 for nested issues

TEMPLATE VERSIONING:
When creating documents from this template, ensure:
1. Use the TEMPLATE_FILE and TEMPLATE_VERSION defined above for metadata fields
2. Fill in all metadata fields with actual values, not placeholders
3. Required fields: issue_type, severity, status
4. Optional fields: All provenance fields (can be omitted for manually-created issues)
═══════════════════════════════════════════════════════════════════════════
-->

**📋 v1.0 TEMPLATE FEATURES**:
- **Template Version**: 1.0.0 (Initial release)
- **Provenance Tracking**: Links issues to discovery context (execution ID, discovery classification, timestamp)
- **Lightweight Workflow**: 3-phase resolution via template.issue-fix.plan
- **Nested Issue Support**: Max depth 1 (original issue can spawn 1 nested child)
- **Lifecycle Management**: Active → Resolved/Deferred with timestamp archival
- **YAML Schema**: issue_type, severity, status, provenance fields, nested issue tracking

## **TEMPLATE USAGE**
This template creates issue documentation using pattern: `ISSUE-NNN-description.issue.req.md`

**Example Usage:**
- File: `ISSUE-024-authentication-timeout.issue.req.md`
- Title: `# Issue: Authentication Timeout - Session Expires Too Quickly`

---

```yaml
---
# =====================================================
# METADATA HEADER - issue.req v1.0.0
# =====================================================

# Required Fields
issue_type: defect             # defect | enhancement
severity: high                 # critical | high | medium | low
status: active                 # active | in_resolution | deferred | resolved

# Provenance Fields (REQUIRED for execution-discovered issues, OPTIONAL for manual)
discovered_during: "manual-analysis-2026-02-17"     # Execution ID or "manual-analysis-YYYYMMDD"
discovery_context: "manual-analysis"                # Classification: "insight-[Anti-Pattern]" | "test-failure" | "qa-review" | "manual-analysis" | "lightsout-execution"
discovered_by: Developer                            # Developer | QA | Stakeholder | Automated_Test | AI_Agent
discovery_timestamp: "2026-02-17 13:30:00"         # ISO 8601: "YYYY-MM-DD HH:MM:SS"

# Reference Fields (OPTIONAL)
source_document: ""                                 # Path to document where issue was discovered
related_features: []                                # List of related features/templates
nested_from: ""                                     # Path to parent issue.req (for nested issues)
resolution_depth: 0                                 # Nesting depth: 0 (original) or 1 (nested). Default: 0

# Resolution Fields (populated during/after resolution)
resolution_icp: ""                                  # Path to issue-fix.plan.md (populated when resolution starts)
resolved_date: ""                                   # ISO 8601 date (populated on resolution completion)
resolution_summary: ""                              # Brief description of fix applied

# Template Metadata
template_file: "template.issue.req.md"
template_version: "1.0.0"
document_version: "1.0.0"
created: "YYYY-MM-DD"
modified: "YYYY-MM-DD"
---
```

---

## Issue Description

### **Observed Behavior**
[Describe what is currently happening that is incorrect or missing. Be specific about symptoms, error messages, or missing functionality.]

**Example (Defect):**
> Authentication sessions expire after 5 minutes of inactivity, forcing users to re-login frequently during normal workflows.

**Example (Enhancement):**
> The domain.req template does not include a "Cross-Feature Integration Scenarios" section, making it difficult to design feature interaction points before implementation.

### **Expected Behavior**
[Describe what should happen instead. Define the correct behavior or the desired capability.]

**Example (Defect):**
> Authentication sessions should remain valid for at least 30 minutes of inactivity, matching industry-standard session timeout practices.

**Example (Enhancement):**
> The domain.req template should include a dedicated section for defining cross-feature integration scenarios with data flow, error boundaries, and acceptance criteria.

### **Impact**
[Explain the business and technical impact of this issue. Who is affected? What workflows are broken or degraded?]

**Example (Defect):**
> **Business Impact**: Users experience frequent disruptions during multi-step workflows (analysis, trade execution), leading to frustration and potential abandonment.
> **Technical Impact**: Excessive re-authentication load on authentication service; increased API traffic for token refresh.

**Example (Enhancement):**
> **Business Impact**: Missing integration scenarios lead to rework during implementation when features don't compose correctly.
> **Technical Impact**: Integration bugs discovered late in the cycle require costly refactoring; end-to-end workflows not designed upfront.

### **Reproduction Steps**
1. [Step-by-step instructions to reproduce the issue (for defects) or demonstrate the gap (for enhancements)]
2. [Include specific commands, file paths, or test cases]
3. [Note any preconditions or environment setup required]

**Example (Defect):**
1. Log in to application
2. Navigate to trading dashboard
3. Wait 6 minutes without interaction
4. Attempt to execute a trade
5. **Observed**: Session expired error, forced to re-login

**Example (Enhancement):**
1. Open `template.domain.req.md` v5.1.0
2. Search for "integration" sections
3. **Observed**: Only "Integration Points" section (focused on domain events), no section for cross-feature workflow design

---

## Root Cause Analysis
[**Placeholder** - This section is filled during issue-fix.plan Phase 1 (Task 1.1: Root Cause Analysis)]

**Root Cause**: [To be determined during resolution]

**Why It Matters**: [Impact explanation - why this root cause leads to the observed behavior]

**Current Workaround**: [If any temporary mitigation exists, describe it here]

**Example (Defect - to be filled during resolution):**
> **Root Cause**: Authentication service session timeout configuration set to 5 minutes (default value from framework). No environment-specific override applied.
> **Why It Matters**: Default timeout is intended for high-security admin interfaces, not standard user workflows. Misconfiguration during initial deployment.
> **Current Workaround**: Users manually refresh browser tab every 4 minutes to keep session alive (undocumented, not sustainable).

---

## Resolution Approach

### **Proposed Fix**
[Describe the proposed resolution. For defects: the fix strategy. For enhancements: the implementation approach.]

**Example (Defect):**
> Update authentication service configuration to set session timeout to 30 minutes for standard user sessions, while maintaining 5-minute timeout for admin sessions. Add environment variable override for deployment-specific tuning.

**Example (Enhancement):**
> Add "Cross-Feature Integration Scenarios" section to domain.req template after "Exploratory Features" section. Include subsections for workflow diagrams, data flow documentation, error boundary definition, and acceptance criteria.

### **Test Strategy**
- **Unit Tests**: [Tests to write - specific test cases]
- **Integration Tests**: [Integration validation - end-to-end scenarios]
- **Regression Tests**: [Existing tests to verify - ensure no breakage]

**Example (Defect):**
- **Unit Tests**: Test session timeout configuration reads environment variable correctly; test separate timeout policies for user vs admin roles
- **Integration Tests**: End-to-end login → wait 25 minutes → execute trade (should succeed); wait 35 minutes → should expire
- **Regression Tests**: Verify all existing authentication tests still pass; verify admin session timeout remains 5 minutes

**Example (Enhancement):**
- **Unit Tests**: Validate template parses correctly; verify new section is included in template structure
- **Integration Tests**: Create sample domain.req using new template; verify integration scenarios section is populated
- **Regression Tests**: Verify all existing domain.req files remain valid; verify template versioning increments correctly

### **Acceptance Criteria**
- [ ] [Criterion 1 - Observable outcome that indicates success]
- [ ] [Criterion 2 - Validation checkpoint]
- [ ] [Criterion 3 - Regression validation]

**Example (Defect):**
- [ ] Session timeout configuration updated to 30 minutes for standard users
- [ ] Admin sessions maintain 5-minute timeout
- [ ] Environment variable override functional
- [ ] All authentication tests pass
- [ ] End-to-end integration test validates 25-minute session persistence

**Example (Enhancement):**
- [ ] "Cross-Feature Integration Scenarios" section added to template.domain.req.md
- [ ] Section includes workflow diagrams, data flow, error boundaries, acceptance criteria subsections
- [ ] Template version incremented to v5.2.0 (MINOR enhancement)
- [ ] Existing domain.req files remain compatible (backward compatible)
- [ ] Template documentation updated with usage examples

---

## Additional Context

### **Related Issues**
- **Related Enhancements**: [Links to related issue.req files or concept.req documents]
- **Dependent Issues**: [Issues that block this one or are blocked by this one]

**Example:**
- Related to ISSUE-015 (API timeout configuration) - same root cause pattern
- Blocks ISSUE-026 (session persistence across microservices)

### **Documentation Updates Required**
[Files that will need updating during issue-fix.plan Phase 3]

**Example:**
- `Documentation/ContextEngineering/authentication.domain.req.md` - Update session management feature specification
- `Documentation/ContextEngineering/authentication.domain.req.md` - Add defect note under session timeout feature

### **Estimated Complexity**
[Rough estimate to validate issue.req is appropriate workflow choice]

**Example (Defect):**
- **Estimated Duration**: 2-3 hours
- **Files Modified**: 1-2 files (authentication service config, environment config)
- **LOC Estimate**: 50-100 lines (config changes + tests)
- **Domain Impact**: Single domain (authentication)
- **Workflow Choice**: ✅ Issue Resolution (within < 4 hours, 1-5 files, single domain)

**Example (Enhancement):**
- **Estimated Duration**: 1-2 hours
- **Files Modified**: 1 file (template.domain.req.md)
- **LOC Estimate**: 150-200 lines (new section + examples)
- **Domain Impact**: Single domain (ContextEngineering templates)
- **Workflow Choice**: ✅ Issue Resolution (within < 4 hours, 1-5 files, single domain)

---

**Issue captured - Ready for issue-fix.plan workflow**

---

**Document Metadata**
- **Template Name**: template.issue.req
- **Generated From Template**: template.issue.req.md v1.0.0
- **Template Version**: 1.0.0 (Initial release - structured issue capture with provenance)
- **Created Date**: YYYY-MM-DD
- **Last Updated**: YYYY-MM-DD
- **Status**: [ ] Draft [x] Active [ ] In Resolution [ ] Deferred [ ] Resolved

**Resolution Tracking**
- **Resolution ICP**: [Path to issue-fix.plan.md - populated when resolution starts]
- **Resolution Started**: [Date - populated when issue-fix.plan created]
- **Resolution Completed**: [Date - populated on archival to Resolved/]

**Lifecycle Notes**
- Issue.req files are created in `Documentation/WorkInProgress/Issues/Active/`
- When resolved, archived to `Documentation/WorkInProgress/Issues/Resolved/` with timestamp prefix
- Archival format: `YYYYMMDD-HHMM-ISSUE-NNN-description.issue.req.md`
- Both issue.req and issue-fix.plan are archived together as a matched pair

---

**AI Implementation Guidance**
When creating issue.req documents from this template:
1. **Required Fields**: issue_type, severity, status (MUST be set)
2. **Provenance Fields**: Optional for manual issues; auto-populated for execution-discovered issues
3. **Nested Issues**: Set resolution_depth = 1 and populate nested_from if spawned during issue-fix.plan
4. **Workflow Selection**: Validate complexity estimate falls within issue.req scope (< 4 hours, 1-5 files, single domain)
5. **Root Cause Analysis**: Leave as placeholder until issue-fix.plan Phase 1
6. **Documentation**: Update template metadata fields (created, modified dates)

**Human Review Focus Areas**
- **Workflow Choice**: Is issue.req the right template, or should this use concept.req (full codification)?
- **Scope Estimate**: Is the complexity estimate realistic (< 4 hours, 1-5 files)?
- **Impact Assessment**: Is the severity classification accurate?
- **Root Cause**: Can root cause be identified before resolution starts, or defer to Phase 1?
