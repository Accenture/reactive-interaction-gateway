# Resolution ICP: [ISSUE-NNN - Issue Title]

<!--
═══════════════════════════════════════════════════════════════════════════
TEMPLATE VERSION DEFINITION (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
TEMPLATE_FILE: template.issue-fix.plan.md
TEMPLATE_VERSION: 1.0.0
TEMPLATE_DESCRIPTION: Initial v1.0 release: Lightweight 3-phase implementation template for resolving issues documented in issue.req files. Designed for < 4 hours effort, 1-5 files, single domain scope. Includes Phase 1 (Analysis & Root Cause), Phase 2 (TDD Implementation: Red/Green/Test/Integration/Insight), Phase 3 (Documentation Update - MANDATORY). Integrates with issue.req lifecycle management for traceability. Supports YAML frontmatter, state persistence blocks, and archival trigger configuration.
═══════════════════════════════════════════════════════════════════════════

TEMPLATE UPDATE INSTRUCTIONS FOR AI (DO NOT INCLUDE IN FINAL DOCUMENTS)
═══════════════════════════════════════════════════════════════════════════
When updating this template, the AI MUST follow these instructions:

1. VERSION INCREMENTATION:
   - Major (x.0.0): Fundamental changes to YAML schema or phase structure
   - Minor (x.y.0): Significant enhancements like new sections or TDD methodology changes
   - Patch (x.y.z): Minor tweaks, typo fixes, or small clarifications
   - ALWAYS increment version when making ANY change
   - UPDATE TEMPLATE_DESCRIPTION to reflect changes

   VERSION 1.0.0 INITIAL RELEASE:
   - 3-Phase Structure: Analysis, Implementation (TDD), Documentation Update
   - YAML frontmatter schema with resolution metadata (source_issue, resolution_type, execution_mode)
   - Phase 1: Tasks 1.1-1.2 (Issue Analysis, Root Cause Identification)
   - Phase 2: Tasks 2.1-2.5 (Red/Green/Test/Integration/Insight TDD cycle)
   - Phase 3: Task 3.1 (Documentation Update - MANDATORY, explicitly non-skippable)
   - State persistence blocks for context rollover resilience
   - Template version block and AI instructions
   - Archival trigger configuration
   - Integration with issue.req lifecycle management

2. YAML SCHEMA BACKWARD COMPATIBILITY:
   - New fields should be OPTIONAL unless explicitly required for new workflows
   - Required fields: source_issue, resolution_type, execution_mode
   - Optional fields: nested_resolution, complexity_estimate

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

RESOLUTION.ICP TEMPLATE USAGE INSTRUCTIONS (DO NOT INCLUDE IN FINAL DOCUMENT)
═══════════════════════════════════════════════════════════════════════════
This template is for implementing resolutions to issues documented in issue.req files.
It follows a lightweight 3-phase workflow optimized for < 4 hours effort, 1-5 files, single domain.

KEY DIFFERENCES from guided-build.plan template:
1. Lightweight scope: < 4 hours effort vs multi-day features
2. Issue-focused: Links directly to source issue.req document
3. 3-phase structure: Analysis → Implementation → Documentation (vs full guided-build.plan phases)
4. Mandatory documentation update: Phase 3 is NOT optional (ensures issue.req updated)
5. Nested resolution support: Can spawn 1 nested issue (max depth 1)

WHEN TO USE RESOLUTION.ICP vs IMPLEMENTATION.ICP:
- Resolution.icp: < 4 hours, 1-5 files, single domain (issue resolution)
- Implementation.icp: Multi-day features, 6+ files, multi-domain (feature implementation)

LIFECYCLE:
- Created in: Documentation/WorkInProgress/Issues/Active/
- Naming: ISSUE-NNN-description.issue-fix.plan.md
- Linked from: source issue.req (resolution_icp field)
- Archived to: Documentation/WorkInProgress/Issues/Resolved/ (with timestamp)
- Format: YYYYMMDD-HHMM-ISSUE-NNN-description.issue-fix.plan.md
- Both issue.req and issue-fix.plan archived together as matched pair

PHASE STRUCTURE:
Phase 1: Analysis and Root Cause (Tasks 1.1-1.2)
- Task 1.1: Read source issue.req and analyze reported behavior
- Task 1.2: Identify root cause and update issue.req

Phase 2: Implementation via TDD (Tasks 2.1-2.5)
- Task 2.1: [Red] Write failing tests for expected behavior
- Task 2.2: [Green] Implement minimal fix to make tests pass
- Task 2.3: [Test] Run full test suite to validate no regressions
- Task 2.4: [Integration] Run integration tests with real dependencies
- Task 2.5: [Insight] Capture learnings and architectural observations

Phase 3: Documentation Update (Task 3.1 - MANDATORY)
- Task 3.1: Update source issue.req and related documentation
- NOT OPTIONAL: Phase 3 must execute (ensures issue.req closed properly)

TEMPLATE VERSIONING:
When creating documents from this template, ensure:
1. Use the TEMPLATE_FILE and TEMPLATE_VERSION defined above for metadata fields
2. Fill in all metadata fields with actual values, not placeholders
3. Required fields: source_issue, resolution_type, execution_mode
4. Optional fields: nested_resolution, complexity_estimate
═══════════════════════════════════════════════════════════════════════════
-->

**📋 v1.0 TEMPLATE FEATURES**:
- **Template Version**: 1.0.0 (Initial release)
- **3-Phase Structure**: Analysis → Implementation (TDD) → Documentation Update
- **Issue Traceability**: Links to source issue.req document
- **TDD Methodology**: Red/Green/Test/Integration/Insight cycle
- **Mandatory Documentation**: Phase 3 is NOT optional (ensures proper closure)
- **Nested Resolution Support**: Can spawn 1 nested issue (max depth 1)
- **State Persistence**: Context rollover resilience
- **YAML Schema**: resolution_type, source_issue, execution_mode, nested_resolution

## **TEMPLATE USAGE**
This template creates resolution documentation using pattern: `ISSUE-NNN-description.issue-fix.plan.md`

**Example Usage:**
- File: `ISSUE-024-authentication-timeout.issue-fix.plan.md`
- Title: `# Resolution ICP: ISSUE-024 - Authentication Timeout`
- Links to: `Documentation/WorkInProgress/Issues/Active/ISSUE-024-authentication-timeout.issue.req.md`

---

```yaml
---
# =====================================================
# METADATA HEADER - issue-fix.plan v1.0.0
# =====================================================

# Required Fields
source_issue: "ISSUE-NNN-description.issue.req.md"     # Path to source issue.req document
resolution_type: defect-fix                             # defect-fix | enhancement | refactoring
execution_mode: manual                                  # manual | autonomous (default: manual)

# Optional Fields
nested_resolution: false                                # Is this a nested resolution? (spawned during another resolution)
nested_from: ""                                         # Path to parent issue-fix.plan (for nested resolutions)
resolution_depth: 0                                     # Nesting depth: 0 (original) or 1 (nested). Default: 0
complexity_estimate: "Simple"                           # Simple | Moderate | Complex (effort indicator)

# Resolution Tracking
resolution_status: in_progress                          # in_progress | completed | deferred
started_date: "YYYY-MM-DD"                             # ISO 8601 date
completed_date: ""                                      # ISO 8601 date (populated on completion)

# Template Metadata
template_file: "template.issue-fix.plan.md"
template_version: "1.0.0"
document_version: "1.0.0"
created: "YYYY-MM-DD"
modified: "YYYY-MM-DD"
---
```

---

<!-- ═══════════════════════════════════════════════════════════════════════════
STATE PERSISTENCE BLOCK
═══════════════════════════════════════════════════════════════════════════
This block enables context rollover recovery. Update after EVERY action.
═══════════════════════════════════════════════════════════════════════════ -->

╔══════════════════════════════════════════════════════════════════════════════════╗
║                         📍 EXECUTION STATE TRACKER                               ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                                  ║
║  CURRENT PHASE: [Not Started]                                                   ║
║  CURRENT TASK: [None]                                                           ║
║                                                                                  ║
║  LAST ACTION COMPLETED:                                                          ║
║  • [None - Resolution ICP execution not yet started]                            ║
║                                                                                  ║
║  NEXT ACTION:                                                                    ║
║  • Read source issue.req document                                               ║
║  • Begin Phase 1, Task 1.1 (Issue Analysis)                                     ║
║                                                                                  ║
║  FILES MODIFIED THIS SESSION: 0                                                  ║
║  • [None yet]                                                                    ║
║                                                                                  ║
║  ROOT CAUSE IDENTIFIED: ❌ Not yet identified                                    ║
║  TESTS WRITTEN: ❌ Not yet written                                               ║
║  TESTS PASSING: ❌ Not yet validated                                             ║
║  DOCUMENTATION UPDATED: ❌ Not yet updated                                       ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝

---

## Phase 1: Analysis and Root Cause

### **Task 1.1: [Analysis] Read and Analyze Source Issue**

**Objective**: Understand the issue thoroughly by reading the source issue.req document.

**Instructions**:
1. Read the source issue.req document (path in frontmatter metadata)
2. Review the "Issue Description" section:
   - Observed Behavior (what is happening)
   - Expected Behavior (what should happen)
   - Impact (business and technical impact)
   - Reproduction Steps (how to reproduce)
3. Review the "Resolution Approach" section:
   - Proposed Fix (resolution strategy)
   - Test Strategy (test coverage plan)
   - Acceptance Criteria (success criteria)
4. Note any related issues or dependencies

**Files to Read**:
- `[source_issue]` (specified in frontmatter)

**Success Criteria**:
- [ ] Source issue.req document read and understood
- [ ] Issue type confirmed (defect vs enhancement)
- [ ] Expected behavior clearly defined
- [ ] Test strategy identified

**Update State Block**:
```
CURRENT PHASE: Phase 1 - Analysis
CURRENT TASK: Task 1.1 - Issue Analysis
LAST ACTION COMPLETED: Read source issue.req document
NEXT ACTION: Begin Task 1.2 - Root Cause Identification
```

---

### **Task 1.2: [Root Cause] Identify Root Cause and Update Issue**

**Objective**: Determine the root cause of the issue and document it in the source issue.req.

**Instructions**:
1. Investigate the codebase to identify root cause:
   - For defects: Find the code causing incorrect behavior
   - For enhancements: Identify what is missing or needs improvement
2. Analyze why the issue exists:
   - Configuration error?
   - Logic bug?
   - Missing feature?
   - Performance bottleneck?
3. Update the "Root Cause Analysis" section in source issue.req:
   - **Root Cause**: [Specific technical cause]
   - **Why It Matters**: [Explanation of why this causes the observed behavior]
   - **Current Workaround**: [Any temporary mitigations in use]
4. Commit changes to issue.req

**Files to Modify**:
- `[source_issue]` (update Root Cause Analysis section)

**Success Criteria**:
- [ ] Root cause identified and documented
- [ ] Root Cause Analysis section in issue.req updated
- [ ] Changes committed with descriptive message

**Update State Block**:
```
CURRENT PHASE: Phase 1 - Analysis
CURRENT TASK: Task 1.2 - Root Cause Identification
LAST ACTION COMPLETED: Root cause identified and documented in issue.req
NEXT ACTION: Begin Phase 2, Task 2.1 - [Red] Write failing tests
ROOT CAUSE IDENTIFIED: ✅ Identified and documented
```

---

## Phase 2: Implementation via TDD

**TDD Cycle**: Red → Green → Test → Integration → Insight

This phase follows Test-Driven Development methodology:
1. **Red**: Write failing tests that specify expected behavior
2. **Green**: Implement minimal code to make tests pass
3. **Test**: Run full test suite to validate no regressions
4. **Integration**: Run integration tests with real dependencies
5. **Insight**: Capture learnings and architectural observations

---

### **Task 2.1: [Red] Write Failing Tests**

**Objective**: Write tests that specify the expected behavior. Tests MUST fail initially.

**Instructions**:
1. Create test file(s) based on test strategy from issue.req
2. Write tests that validate expected behavior:
   - For defects: Tests that fail due to the bug
   - For enhancements: Tests for the new capability
3. Run tests to verify they FAIL (Red phase)
4. Do NOT implement the fix yet (tests must fail first)
5. Commit test code with message: `test: [Red] Add failing tests for ISSUE-NNN`

**Test Quality Criteria**:
- Tests validate business behavior (not just code coverage)
- Tests use realistic data (not hardcoded magic values)
- Tests demonstrate domain understanding
- Tests are specific to the issue being resolved

**Files to Modify**:
- Test files (create new or modify existing)

**Success Criteria**:
- [ ] Tests written and committed
- [ ] Tests FAIL when run (Red phase verified)
- [ ] Tests validate expected behavior from issue.req
- [ ] Commit message follows pattern

**Update State Block**:
```
CURRENT PHASE: Phase 2 - Implementation (TDD)
CURRENT TASK: Task 2.1 - [Red] Write failing tests
LAST ACTION COMPLETED: Failing tests written and committed
NEXT ACTION: Task 2.2 - [Green] Implement fix
TESTS WRITTEN: ✅ Written (FAILING)
```

---

### **Task 2.2: [Green] Implement Fix**

**Objective**: Implement the minimal code necessary to make tests pass.

**Instructions**:
1. Implement the fix or enhancement:
   - For defects: Fix the root cause identified in Task 1.2
   - For enhancements: Add the missing capability
2. Keep implementation minimal (just enough to pass tests)
3. Run tests to verify they PASS (Green phase)
4. Do NOT add extra features or refactoring yet
5. Commit implementation with message: `feat: [Green] Implement fix for ISSUE-NNN` or `fix: [Green] Resolve ISSUE-NNN`

**Implementation Criteria**:
- Minimal code changes (only what's needed for tests to pass)
- No over-engineering or gold-plating
- Clear and readable code
- Follows existing code patterns and conventions

**Files to Modify**:
- Source code files (1-5 files per issue.req scope)

**Success Criteria**:
- [ ] Fix implemented and committed
- [ ] Tests PASS when run (Green phase verified)
- [ ] Implementation is minimal and focused
- [ ] Commit message follows pattern

**Update State Block**:
```
CURRENT PHASE: Phase 2 - Implementation (TDD)
CURRENT TASK: Task 2.2 - [Green] Implement fix
LAST ACTION COMPLETED: Fix implemented and tests passing
NEXT ACTION: Task 2.3 - [Test] Run full test suite
TESTS PASSING: ✅ PASSING (Green phase complete)
```

---

### **Task 2.3: [Test] Run Full Test Suite**

**Objective**: Validate that the fix does not break existing functionality.

**Instructions**:
1. Run the full test suite for the affected domain/project
2. Verify ALL tests pass (not just the new tests)
3. If any tests fail:
   - Analyze the failure
   - Fix the regression
   - Re-run tests until all pass
4. Document test results in this section

**Test Execution**:
```bash
# Example commands (adjust for your project)
npm test                    # JavaScript/TypeScript projects
dotnet test                 # .NET projects
pytest                      # Python projects
```

**Success Criteria**:
- [ ] Full test suite executed
- [ ] ALL tests pass (no regressions)
- [ ] Test results documented
- [ ] Any regressions fixed

**Update State Block**:
```
CURRENT PHASE: Phase 2 - Implementation (TDD)
CURRENT TASK: Task 2.3 - [Test] Run full test suite
LAST ACTION COMPLETED: Full test suite passing
NEXT ACTION: Task 2.4 - [Integration] Run integration tests
```

---

### **Task 2.4: [Integration] Run Integration Tests**

**Objective**: Validate that the fix works correctly with real dependencies.

**Instructions**:
1. Run integration tests (if available) for the affected domain
2. Validate behavior with real dependencies:
   - Database connections (if applicable)
   - External services (if applicable)
   - File system operations (if applicable)
3. If integration tests don't exist, perform manual integration validation:
   - Start the application
   - Reproduce the original issue scenario
   - Verify the issue is resolved
4. Document integration test results

**Integration Validation**:
- Integration tests pass (if automated)
- OR manual validation confirms fix works end-to-end

**Success Criteria**:
- [ ] Integration tests executed (automated or manual)
- [ ] Integration validation successful
- [ ] Fix verified with real dependencies
- [ ] Results documented

**Update State Block**:
```
CURRENT PHASE: Phase 2 - Implementation (TDD)
CURRENT TASK: Task 2.4 - [Integration] Integration tests
LAST ACTION COMPLETED: Integration validation successful
NEXT ACTION: Task 2.5 - [Insight] Capture learnings
```

---

### **Task 2.5: [Insight] Capture Learnings**

**Objective**: Document insights and learnings from the resolution process.

**Instructions**:
1. Generate a "★ Insight" block capturing key learnings:
   - What was discovered during root cause analysis?
   - Any architectural observations?
   - Performance considerations?
   - Security concerns addressed?
   - Patterns that could prevent similar issues?
2. Include the insight block in this document
3. Learnings will be automatically extracted at completion (F007)

**Insight Block Format**:
```
★ Insight ─────────────────────────────────────
**[Key learning or discovery from this resolution]**
- [Implementation detail or architectural decision]
- [Performance consideration or optimization applied]
- [Security concern addressed]
- [Pattern to prevent similar issues]
─────────────────────────────────────────────────
```

**Example Insight**:
```
★ Insight ─────────────────────────────────────
**Session timeout configuration should be role-specific**
- Authentication service now supports separate timeout policies for user vs admin roles
- Default framework timeout (5 minutes) is too aggressive for standard user workflows
- Environment variable overrides enable deployment-specific tuning without code changes
- Pattern: Configuration stratification by user role improves UX without compromising security
─────────────────────────────────────────────────
```

**Success Criteria**:
- [ ] At least 1 insight block generated
- [ ] Insight captures meaningful learning (not superficial observation)
- [ ] Insight formatted correctly

**Update State Block**:
```
CURRENT PHASE: Phase 2 - Implementation (TDD)
CURRENT TASK: Task 2.5 - [Insight] Capture learnings
LAST ACTION COMPLETED: Insights documented
NEXT ACTION: Phase 3, Task 3.1 - Documentation Update
```

---

## Phase 3: Documentation Update (MANDATORY)

**IMPORTANT**: This phase is NOT OPTIONAL. Documentation must be updated to close the issue properly.

---

### **Task 3.1: [Documentation] Update Source Issue and Related Docs**

**Objective**: Update issue.req status and any related documentation identified during resolution.

**Instructions**:
1. Update source issue.req document:
   - Set `status: resolved` in YAML frontmatter
   - Populate `resolution_icp: [path to this issue-fix.plan]`
   - Populate `resolved_date: [YYYY-MM-DD]`
   - Add `resolution_summary: [Brief description of fix applied]`
2. Update "Resolution Approach" section with actual resolution details (if different from proposed)
3. Update any related documentation files identified in "Additional Context > Documentation Updates Required":
   - Domain.req files (if applicable)
   - Digital.req files (if applicable)
   - README files (if applicable)
   - Architecture documentation (if applicable)
4. Commit all documentation changes with message: `docs: Update documentation for ISSUE-NNN resolution`

**Files to Modify**:
- `[source_issue]` (YAML frontmatter + Resolution Approach section)
- Any related documentation files from issue.req

**Success Criteria**:
- [ ] Source issue.req status updated to "resolved"
- [ ] Resolution metadata fields populated
- [ ] Related documentation updated
- [ ] All changes committed

**Update State Block**:
```
CURRENT PHASE: Phase 3 - Documentation Update
CURRENT TASK: Task 3.1 - Update documentation
LAST ACTION COMPLETED: All documentation updated
NEXT ACTION: Archive issue.req and issue-fix.plan to Resolved/
DOCUMENTATION UPDATED: ✅ Updated
```

---

## **Completion and Archival**

**Archival Trigger**:
After Task 3.1 completes, both the issue.req and this issue-fix.plan should be archived together.

**Archival Steps**:
1. Create timestamp prefix: `YYYYMMDD-HHMM` (e.g., `20260217-1430`)
2. Move files to `Documentation/WorkInProgress/Issues/Resolved/`:
   - `YYYYMMDD-HHMM-ISSUE-NNN-description.issue.req.md`
   - `YYYYMMDD-HHMM-ISSUE-NNN-description.issue-fix.plan.md`
3. Both files archived as matched pair with same timestamp

**Example**:
```
Active/ISSUE-024-authentication-timeout.issue.req.md
  → Resolved/20260217-1430-ISSUE-024-authentication-timeout.issue.req.md

Active/ISSUE-024-authentication-timeout.issue-fix.plan.md
  → Resolved/20260217-1430-ISSUE-024-authentication-timeout.issue-fix.plan.md
```

**Final State Block Update**:
```
CURRENT PHASE: Completed
CURRENT TASK: None (resolution complete)
LAST ACTION COMPLETED: Documentation archived to Resolved/
NEXT ACTION: None (workflow complete)
ROOT CAUSE IDENTIFIED: ✅ Identified and documented
TESTS WRITTEN: ✅ Written and PASSING
TESTS PASSING: ✅ ALL tests passing
DOCUMENTATION UPDATED: ✅ Updated and archived
```

---

## **Resolution Summary**

**Issue Resolved**: [ISSUE-NNN - Issue Title]

**Root Cause**: [Brief summary of root cause from Task 1.2]

**Resolution Applied**: [Brief summary of fix from Task 2.2]

**Tests Added**: [Number of test cases added]

**Files Modified**: [List of files modified during resolution]

**Insights Captured**: [Number of insight blocks generated]

**Documentation Updated**: [List of documentation files updated]

**Resolution Completion Date**: [YYYY-MM-DD]

---

**Document Metadata**
- **Template Name**: template.issue-fix.plan
- **Generated From Template**: template.issue-fix.plan.md v1.0.0
- **Template Version**: 1.0.0 (Initial release - lightweight 3-phase issue resolution)
- **Created Date**: YYYY-MM-DD
- **Last Updated**: YYYY-MM-DD
- **Resolution Status**: [ ] In Progress [x] Completed [ ] Deferred

**Source Issue Reference**
- **Issue Document**: [Path to source issue.req]
- **Issue Type**: [ ] Defect [x] Enhancement
- **Severity**: [ ] Critical [ ] High [x] Medium [ ] Low

**Lifecycle Notes**
- Resolution.icp files are created in `Documentation/WorkInProgress/Issues/Active/`
- When resolved, archived to `Documentation/WorkInProgress/Issues/Resolved/` with timestamp prefix
- Archival format: `YYYYMMDD-HHMM-ISSUE-NNN-description.issue-fix.plan.md`
- Both issue.req and issue-fix.plan are archived together as a matched pair

---

**AI Implementation Guidance**
When creating issue-fix.plan documents from this template:
1. **Required Fields**: source_issue, resolution_type, execution_mode (MUST be set)
2. **Phase Execution**: Follow phases sequentially (Analysis → Implementation → Documentation)
3. **TDD Discipline**: Write tests BEFORE implementation (Red → Green → Test → Integration → Insight)
4. **Documentation Update**: Phase 3 is MANDATORY (not optional)
5. **State Persistence**: Update state block after each task
6. **Insights**: Generate at least 1 meaningful insight block
7. **Archival**: Both issue.req and issue-fix.plan archived together with same timestamp

**Human Review Focus Areas**
- **Root Cause Validation**: Is the root cause accurate and complete?
- **Test Coverage**: Are tests comprehensive and meaningful (not superficial)?
- **Fix Quality**: Is the implementation minimal and focused (no over-engineering)?
- **Documentation Completeness**: Are all related docs updated?
- **Insights Quality**: Are insights meaningful learnings (not obvious statements)?
