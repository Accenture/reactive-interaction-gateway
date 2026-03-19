# Lights Out Implementation Protocol (ICP) - Template v3.0

**Status**: Template Document
**Version**: 3.0.1
**Compatible With**: DDE workflow v6.0.0+
**Target Audience**: Autonomous AI Agents (Claude Code + Multi-Agent Swarms)
**Execution Mode**: Dual-Mode (Sequential Single-Agent OR Parallel Multi-Agent Swarm)

**Changelog v3.0.1** (F019 DAG-Driven Pipeline Integration):
- **Pipeline Checkpoint Configuration**: New `pipeline_checkpoints` frontmatter section for CI/CD integration
- **DAG-Driven Checkpoints**: Trigger pipeline validation at leaf_node_completion, convergence_point, phase_boundary
- **Ralph Wiggum Pattern**: Automatic unplanned task spawning on pipeline failure (spawn fix task → retry)
- **PHASE FINAL Redesign**: Changed from manual smoke test to automated DAG checkpoint
- **Execution Engine Separation**: Clarified "for execution engine" vs "for AI agent" responsibilities
- **Integration Failure Recovery**: Documented retry logic, max_retries, and human escalation paths
- Addresses F019 requirement: Autonomous execution must integrate with Azure Pipelines at meaningful completion points

**Changelog v3.0.0** (F030 Swarm ICP Templates):
- **Swarm Execution Mode Support**: Added `swarm_mode` field ("sequential" | "swarm") for dual-mode execution
- **Agent Pool Configuration**: New `agent_pool` section defines max_agents, mini_swarm_size, shared_specialists
- **Wave-Based Execution**: New `wave_config` for parallel task waves with quorum thresholds
- **DAG Dependency Graph**: New `dag_dependencies` for explicit/file/semantic dependency tracking
- **3-Level Rollback Strategy**: New `rollback` configuration with Level 1/2/3 escalation paths
- **Backward Compatibility**: All v2.5 ICPs continue to work unchanged (default swarm_mode: "sequential")
- **Template Version Detection**: Parser auto-detects execution mode from swarm_mode field
- Addresses F030 Phase 5: Template upgrade for swarm-integrated autonomous execution

**Changelog v2.5.0**:
- **Standardized ICP Chain Naming Convention**: Hybrid semantic pattern (`001-<semantic-name>`) for all child ICPs
- Lowercase `parent` suffix for parent ICPs (metadata consistency)
- Added explicit ICP Chain Naming Convention section with examples and rationale
- Updated all chain examples to use standardized naming (`001-domain`, `002-services`, etc.)
- Production-aligned: Formalizes existing codebase pattern (`phase-1-core-dashboard.autonomous-build.plan.md`)
- Addresses expert team consensus: Semantic phase names critical for human readability and discovery

**Changelog v2.4.0**:
- Added [Integration] as fifth step in TDD loop: Red → Green → Test → **Integration** → Insight (R3)
- Integration step runs cross-component tests with real dependencies (no mocks) — autonomous verification
- Added mandatory PHASE FINAL: End-to-End Smoke Test before completion (R4)
- Smoke test executes real workflow with real inputs, validates deployment, blocks merge on failure
- Addresses pipeline effectiveness analysis: 225 unit tests passed but 16+ issues on first real execution

**Changelog v2.3.0**:
- Enhanced Phase 0 with project structure validation (greenfield detection)
- Added conditional infrastructure setup tasks for missing projects
- Added dependency installation automation (NuGet, npm, etc.)
- Added test infrastructure setup (bUnit, Jest, xUnit)
- Resolves ISSUE-003: Missing project structure validation gap

---

## YAML Frontmatter

```yaml
---
execution_id: "GENERATE_UUID_V4_AT_START"
icp_type: "single"  # single|parent|child (NEW in v2.2)
status: "pending"  # pending|in_progress|paused|completed|failed
branch_name: ""
pipeline_batch_id: ""
last_checkpoint: ""
start_time: ""
end_time: ""
total_tasks: 0
completed_tasks: 0
failed_tasks: 0
insight_count: 0
test_pass_rate: 0.0

# ICP Chain Fields (NEW in v2.2) - Only for parent/child types
child_icps: []  # Array of child ICP paths (parent only)
parent_icp: ""  # Path to parent ICP (child only)
phase_number: 0  # Phase number within parent (child only, 1-indexed)
dependencies:  # Phase dependencies (parent only)
  sequential: []  # Array of phase numbers that must run in order
  parallel: []  # Array of phase number groups that can run concurrently

# === NEW v3.0 FIELDS (F030 Swarm Execution Support) ===

# Swarm execution mode toggle (NEW in v3.0)
swarm_mode: "sequential"  # sequential | swarm
# - sequential: Single agent executes tasks in order (v2.5 behavior, default)
# - swarm: Multi-agent parallel execution with DAG scheduling (NEW)

# Agent pool configuration (only used when swarm_mode: "swarm")
agent_pool:
  max_agents: 12  # Maximum concurrent agents in swarm
  mini_swarm_size: 3  # Minimum agents per wave (quorum requirement)
  shared_specialists: 3  # Number of shared specialist agents (Orchestrator, Semantic, Doc-Sync)
  orchestrator_count: 1  # Number of orchestrator agents (typically 1)

# Wave execution configuration (only used when swarm_mode: "swarm")
wave_config:
  max_parallel_waves: 1  # Maximum waves executing concurrently (1 = sequential waves)
  max_tasks_per_wave: 4  # Maximum tasks per wave (limits parallelism)
  wave_transition: "all_complete"  # all_complete | quorum
  # - all_complete: Wait for all agents in wave to finish (strict)
  # - quorum: Proceed when quorum_threshold% agents finish (faster, riskier)
  quorum_threshold: 0.75  # Threshold for quorum mode (0.0-1.0, e.g., 0.75 = 75%)

# DAG dependency graph (only used when swarm_mode: "swarm")
dag_dependencies:
  explicit: []  # Explicit task dependencies
  # Example: [{source: "task-1", target: "task-2", type: "file_dependency", description: "Task 2 needs Task 1 output"}]

  file_conflicts: []  # File conflict prevention
  # Example: [{files: ["User.ts", "UserService.ts"], strategy: "sequential"}]

  semantic_domains: []  # Semantic domain boundaries
  # Example: [{domain: "Domain", agents: ["domain-agent-1", "domain-agent-2"]}]

# 3-level rollback configuration (only used when swarm_mode: "swarm")
rollback:
  level_1_max_retries: 3  # Max retries before Level 2 escalation
  level_1_backoff_base_ms: 1000  # Exponential backoff base (ms)
  level_2_pause_on_failure: true  # Pause swarm on Level 2 (manual intervention)
  level_3_git_rollback: true  # Enable git reset --hard on catastrophic failure
  known_good_commit: ""  # Last known good commit SHA for Level 3 rollback

# Pipeline checkpoint configuration (NEW in v3.0.1)
# Determines when to trigger CI/CD pipeline validation during autonomous execution
pipeline_checkpoints:
  strategy: "dag_driven"  # dag_driven | phase_driven | manual | disabled
  # - dag_driven: Trigger at DAG checkpoints (leaf_node_completion, convergence_point) (RECOMMENDED)
  # - phase_driven: Trigger at fixed phase boundaries (after each phase completes)
  # - manual: No automatic triggering (agent must explicitly call pipeline trigger tool)
  # - disabled: No pipeline integration (for offline/local development)

  trigger_on:  # Checkpoint types that trigger pipeline validation (only for dag_driven/phase_driven)
    - "leaf_node_completion"  # Trigger when DAG leaf node completes (phase/feature done)
    - "convergence_point"  # Trigger when multiple branches converge (integration point)
    - "phase_boundary"  # Trigger at explicit phase transitions (phase N → phase N+1)

  failure_handling:
    action: "spawn_unplanned_task"  # spawn_unplanned_task | rollback | escalate | ignore
    # - spawn_unplanned_task: Create unplanned fix task, retry pipeline (RECOMMENDED - "Ralph Wiggum pattern")
    # - rollback: Execute rollback_config Level 2 (reset to phase start)
    # - escalate: Pause execution, notify human immediately
    # - ignore: Log failure but continue execution (RISKY - not recommended)

    max_retries: 3  # Maximum pipeline retry attempts after unplanned fix tasks
    escalate_after: 3  # Escalate to human after N failed retries

  expected_duration_minutes: 5  # Expected pipeline duration for timeout calculation
  timeout_minutes: 10  # Maximum wait time before timeout (typically 2x expected duration)
---
```

**Execution Metadata Fields**:
- `execution_id`: UUID v4, generated once at Phase 0, immutable
- `icp_type`: Determines execution mode (see ICP Chain Pattern below)
- `status`: Workflow state machine (see State Transitions below)
- `branch_name`: Git branch created at Phase 0 (format: `lightsout/<feature-id>-<timestamp>`)
- `pipeline_batch_id`: Azure DevOps pipeline run ID for correlation with Seq logs
- `last_checkpoint`: ISO 8601 timestamp of last state block update
- `insight_count`: Cumulative insights captured via extract-session-learnings
- `test_pass_rate`: Percentage of tasks with passing tests (updated per loop)

**ICP Chain Fields** (NEW in v2.2):
- `icp_type`: "single" (standalone), "parent" (orchestrator), or "child" (phase executor)
- `child_icps`: Array of relative paths to child ICPs (parent only)
- `parent_icp`: Relative path to parent ICP (child only)
- `phase_number`: Phase number within parent chain (child only, 1-indexed)
- `dependencies`: Phase execution dependencies (parent only)
  - `sequential`: Array of phase numbers that MUST run in order (e.g., [1, 2, 3])
  - `parallel`: Array of phase number groups that CAN run concurrently (e.g., [[4, 5], [6, 7]])

**State Transitions**:
```
pending → in_progress → completed
          ↓
          paused → in_progress
          ↓
          failed (terminal)
```

---

## Document Structure

### Phase 0: Initialization

**Objective**: Validate project infrastructure and prepare autonomous execution environment

**Acceptance Criteria**:
- [ ] Project structure validated (infrastructure exists or created)
- [ ] Required dependencies installed (NuGet, npm, etc.)
- [ ] Test infrastructure configured (bUnit, xUnit, Jest, etc.)
- [ ] Execution ID generated and recorded
- [ ] Git branch created following naming convention
- [ ] Pipeline integration validated (credentials, endpoints)
- [ ] Seq debugging access confirmed
- [ ] First checkpoint written

**Steps**:

0. **Validate Project Infrastructure** (NEW in v2.3 - CRITICAL)

   **Purpose**: Detect greenfield projects and create missing infrastructure before TDD loop begins

   **Pre-Flight Checks**:
   ```bash
   # Detect project type from digital.req or domain.req
   # Check for existing project files

   # For Blazor/ASP.NET projects:
   if ! find . -name "*.csproj" -path "*/src/*" | grep -q .; then
     echo "⚠️ GREENFIELD DETECTED: No .csproj files in src/"
     GREENFIELD_DOTNET=true
   fi

   # For React/Vue/Angular projects:
   if ! [ -f "package.json" ]; then
     echo "⚠️ GREENFIELD DETECTED: No package.json in project root"
     GREENFIELD_NPM=true
   fi

   # For Test Projects:
   if ! find . -name "*Tests.csproj" -path "*/tests/*" | grep -q .; then
     echo "⚠️ GREENFIELD DETECTED: No test projects in tests/"
     GREENFIELD_TESTS_DOTNET=true
   fi
   ```

   **Conditional Setup Tasks** (execute only if GREENFIELD flags set):

   **TASK 0.1: Create .NET Project Structure** (if GREENFIELD_DOTNET=true)
   ```bash
   # Example for Blazor Server (adjust based on digital.req technology)
   PROJECT_NAME="YourProject.Dashboard"
   dotnet new blazorserver -o "src/$PROJECT_NAME" --no-https
   dotnet sln add "src/$PROJECT_NAME/$PROJECT_NAME.csproj"

   # Configure Program.cs, _Imports.razor, etc.
   # (Project-specific setup based on digital.req)
   ```

   **TASK 0.2: Install .NET Dependencies** (if GREENFIELD_DOTNET=true)
   ```bash
   # Install required NuGet packages
   cd "src/$PROJECT_NAME"

   # UI Framework (e.g., MudBlazor for Blazor)
   dotnet add package MudBlazor

   # SignalR (for real-time features)
   dotnet add package Microsoft.AspNetCore.SignalR.Client

   # Markdown rendering (if specified)
   dotnet add package Markdig

   # Domain/Application layer references
   dotnet add reference "../YourProject.Domain/YourProject.Domain.csproj"

   cd ../..
   ```

   **TASK 0.3: Create Test Project** (if GREENFIELD_TESTS_DOTNET=true)
   ```bash
   TEST_PROJECT_NAME="YourProject.Dashboard.Tests"
   dotnet new xunit -o "tests/$TEST_PROJECT_NAME"
   dotnet sln add "tests/$TEST_PROJECT_NAME/$TEST_PROJECT_NAME.csproj"

   cd "tests/$TEST_PROJECT_NAME"

   # Install testing frameworks
   dotnet add package bUnit  # For Blazor component testing
   dotnet add package FluentAssertions
   dotnet add package Moq

   # Add reference to project under test
   dotnet add reference "../../src/$PROJECT_NAME/$PROJECT_NAME.csproj"

   cd ../..
   ```

   **TASK 0.4: Create npm Project Structure** (if GREENFIELD_NPM=true)
   ```bash
   # Initialize package.json
   npm init -y

   # Install React/Vue/Angular (based on digital.req)
   # Example for React:
   npm install react react-dom
   npm install -D @types/react @types/react-dom
   npm install -D vite @vitejs/plugin-react

   # Install UI library (e.g., Material-UI, Ant Design)
   npm install @mui/material @emotion/react @emotion/styled

   # Create src/ directory structure
   mkdir -p src/components src/services src/hooks
   ```

   **TASK 0.5: Create npm Test Infrastructure** (if GREENFIELD_NPM=true)
   ```bash
   # Install testing frameworks
   npm install -D vitest @testing-library/react @testing-library/jest-dom
   npm install -D @testing-library/user-event

   # Create vitest.config.ts
   cat > vitest.config.ts <<EOF
   import { defineConfig } from 'vitest/config'
   import react from '@vitejs/plugin-react'

   export default defineConfig({
     plugins: [react()],
     test: {
       environment: 'jsdom',
       globals: true,
       setupFiles: './tests/setup.ts'
     }
   })
   EOF

   # Create test setup file
   mkdir -p tests
   cat > tests/setup.ts <<EOF
   import '@testing-library/jest-dom'
   EOF
   ```

   **Validation**:
   ```bash
   # Verify .NET projects compile
   if [ "$GREENFIELD_DOTNET" = true ]; then
     dotnet build
     if [ $? -ne 0 ]; then
       echo "❌ FATAL: .NET project creation failed"
       exit 1
     fi
   fi

   # Verify npm project compiles
   if [ "$GREENFIELD_NPM" = true ]; then
     npm run build
     if [ $? -ne 0 ]; then
       echo "❌ FATAL: npm project creation failed"
       exit 1
     fi
   fi

   # Verify test infrastructure works
   if [ "$GREENFIELD_TESTS_DOTNET" = true ]; then
     dotnet test
     # Expect 0 tests (no test files yet), but framework should load
   fi

   echo "✅ Infrastructure validation complete"
   ```

   **When to Skip Phase 0 Infrastructure Setup**:
   - ✅ .csproj files exist in src/ (NOT greenfield .NET)
   - ✅ package.json exists (NOT greenfield npm)
   - ✅ Test projects exist in tests/ (NOT greenfield tests)
   - ➡️ If ALL infrastructure exists, skip Tasks 0.1-0.5 and proceed directly to Step 1

   **Checkpoint**: Update state block with infrastructure validation results
   ```markdown
   ## State Block - Phase 0.0 Complete

   **Timestamp**: 2026-02-05T03:00:00Z
   **Infrastructure Status**: greenfield_detected | existing_infrastructure
   **Projects Created**: [list of .csproj or package.json files created]
   **Dependencies Installed**: [list of NuGet/npm packages]
   **Test Framework**: bUnit | xUnit | Vitest | Jest
   **Checkpoint**: Infrastructure ready for TDD loop
   ```

1. **Generate Execution Context**
   ```bash
   # Generate UUID v4
   EXECUTION_ID=$(uuidgen)

   # Update YAML frontmatter
   status: "in_progress"
   execution_id: "$EXECUTION_ID"
   start_time: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   ```

2. **Create Feature Branch**
   ```bash
   # Branch naming: lightsout/<feature-id>-<timestamp>
   BRANCH_NAME="lightsout/F999-feature-name-$(date +%Y%m%d-%H%M%S)"
   git checkout -b "$BRANCH_NAME"
   git push -u origin "$BRANCH_NAME"

   # Update YAML frontmatter
   branch_name: "$BRANCH_NAME"
   ```

3. **Validate Pipeline Integration**
   ```bash
   # Check Azure DevOps credentials
   az devops configure --defaults organization=https://dev.azure.com/yourorg project=YourProject

   # Verify SEQ_ADMIN_PASSWORD in pipeline variables
   az pipelines variable list --pipeline-name "YourPipeline" | grep SEQ_ADMIN_PASSWORD
   ```

4. **Confirm Seq Access**
   ```bash
   # Test Seq endpoint (ubuntu-devops.lan:5341)
   curl -s http://ubuntu-devops.lan:5341/api/events \
     -H "X-Seq-ApiKey: $SEQ_ADMIN_PASSWORD" | jq '.Events | length'
   ```

5. **Write Initial Checkpoint**
   ```markdown
   ## State Block - Phase 0 Complete

   **Timestamp**: 2026-01-26T14:30:00Z
   **Status**: in_progress
   **Execution ID**: abc-123-def-456
   **Branch**: lightsout/F999-feature-name-20260126-143000
   **Checkpoint**: Phase 0 complete, ready for TDD loop
   ```

---

### Phase 1: Feature Implementation (TDD Loop)

**Objective**: Implement feature using Red → Green TDD cycles with Ralph's principle

**Acceptance Criteria**:
- [ ] All tasks broken down to 100-200 LOC maximum
- [ ] Each task follows Red → Green → Test → Integration → Insight pattern
- [ ] Pipeline unit tests pass ([Test] step)
- [ ] Cross-component integration tests pass with real dependencies ([Integration] step)
- [ ] Insights extracted after each loop (if applicable)
- [ ] All checkpoints written

**Task Breakdown Template**:

```markdown
#### Task 1.1: [Red] Write Failing Test for Core Value Object

**Type**: red
**Estimated LOC**: 80
**Time Bound**: 15 minutes
**Risk Level**: low
**Requires Approval**: false

**Test Objective**: Validate immutable value object creation with invalid inputs

**Steps**:
1. Create test file: `tests/Domain/ValueObjects/PricePointTests.cs`
2. Write test case: `Constructor_WithNegativePrice_ThrowsArgumentException()`
3. Write test case: `Constructor_WithFutureTimestamp_ThrowsArgumentException()`
4. Run test suite (expect failures)
5. Commit with message: "test: Add failing tests for PricePoint value object"

**Expected Outcome**: 2 failing tests, 0 passing

**Checkpoint**: Update state block with task completion and failure count
```

```markdown
#### Task 1.2: [Green] Implement Core Value Object

**Type**: green
**Estimated LOC**: 120
**Time Bound**: 20 minutes
**Risk Level**: low
**Requires Approval**: false

**Implementation Objective**: Create immutable PricePoint value object with validation

**Steps**:
1. Create class: `src/Domain/ValueObjects/PricePoint.cs`
2. Implement constructor with guard clauses (price > 0, timestamp <= now)
3. Implement `Equals()` and `GetHashCode()` for value semantics
4. Add XML documentation comments
5. Run test suite (expect all tests pass)
6. Commit with message: "feat: Implement PricePoint value object with validation"

**Expected Outcome**: 2 passing tests, 0 failing

**Checkpoint**: Update state block with task completion and test pass rate
```

```markdown
#### Task 1.3: [Test] Run Integration Tests via Pipeline

**Type**: test
**Estimated LOC**: 0 (infrastructure)
**Time Bound**: 10 minutes (execution + polling)
**Risk Level**: medium
**Requires Approval**: false

**Test Objective**: Validate changes in full integration environment

**Steps**:
1. Push branch to remote
   ```bash
   git push origin "$BRANCH_NAME"
   ```

2. Trigger pipeline build
   ```bash
   PIPELINE_RUN_ID=$(az pipelines run \
     --name "YourPipeline" \
     --branch "$BRANCH_NAME" \
     --query "id" -o tsv)

   # Update YAML frontmatter
   pipeline_batch_id: "$PIPELINE_RUN_ID"
   ```

3. Poll for completion (max 5 minutes)
   ```bash
   while true; do
     STATUS=$(az pipelines runs show --id "$PIPELINE_RUN_ID" --query "status" -o tsv)
     if [[ "$STATUS" == "completed" ]]; then
       RESULT=$(az pipelines runs show --id "$PIPELINE_RUN_ID" --query "result" -o tsv)
       break
     fi
     sleep 10
   done
   ```

4. If RESULT != "succeeded", query Seq logs
   ```bash
   # Correlation query using pipeline_batch_id
   curl -s "http://ubuntu-devops.lan:5341/api/events?filter=PipelineBatchId='$PIPELINE_RUN_ID'" \
     -H "X-Seq-ApiKey: $SEQ_ADMIN_PASSWORD" | jq '.Events[] | select(.Level == "Error")'
   ```

**Expected Outcome**: Pipeline status "succeeded", no errors in Seq logs

**Checkpoint**: Update state block with pipeline result
```

```markdown
#### Task 1.4: [Integration] Cross-Component Integration Verification

**Type**: integration
**Estimated LOC**: 50-150 (integration test code)
**Risk Level**: medium
**Requires Approval**: false

**Integration Objective**: Verify the new code works with existing components using real (not mocked) dependencies

**CRITICAL**: This step uses REAL dependencies — real database connections, real API clients, real file systems. No mocks, no stubs, no fakes. The purpose is to catch integration failures that unit tests miss.

**When to Execute**:
- ALWAYS execute when the task touches a cross-feature boundary (calls code from another feature)
- ALWAYS execute when the task creates or consumes data used by other components
- MAY SKIP only for purely internal tasks with no cross-component interaction (document skip rationale in checkpoint)

**Steps**:
1. Identify integration points touched by this task
   - What components does this code call?
   - What components consume this code's output?
   - What shared state (database, files, config) does this code read/write?

2. Run existing integration test suite (if any)
   ```bash
   # Run integration tests (separate from unit tests)
   npm test -- --testPathPattern="integration" 2>&1 || true
   # OR for .NET:
   dotnet test --filter "Category=Integration" 2>&1 || true
   ```

3. Write new integration test if cross-feature boundary is new
   - Test with real dependencies (database, API clients, file system)
   - Verify data flows correctly across component boundaries
   - Verify error propagation (errors are not silently swallowed)

4. Validate no existing integration tests broke
   ```bash
   # If integration tests fail, this task FAILS — do not proceed to [Insight]
   # Fix the integration issue before continuing
   ```

5. Commit integration test: "test(integration): Verify [component A] integrates with [component B]"

**Expected Outcome**: All integration tests pass, no cross-component regressions

**Failure Protocol** (autonomous):
- If integration tests fail: task status = FAILED
- Orchestrator attempts fix (max 2 retries)
- If fix fails: pause execution, escalate to human review
- Do NOT proceed to [Insight] with failing integration tests

**Checkpoint**: Update state block with integration test results (pass count, fail count, components verified)
```

```markdown
#### Task 1.5: [Insight] Extract Session Learnings

**Type**: insight
**Estimated LOC**: 0 (metadata)
**Time Bound**: 5 minutes
**Risk Level**: low
**Requires Approval**: false

**Insight Objective**: Capture learnings from Red → Green → Test loop

**Trigger Conditions** (call extract-session-learnings if ANY true):
- ✅ Test failures revealed incorrect assumptions
- ✅ Refactoring improved code structure
- ✅ Pipeline errors required debugging
- ✅ Architectural pattern emerged
- ❌ Routine implementation with no surprises (skip tool call)

**Steps**:
1. Review changes since last checkpoint
   ```bash
   git diff HEAD~3  # Last 3 commits (Red, Green, Test)
   ```

2. Identify learnings:
   - Domain insights (ubiquitous language, value object patterns)
   - Technical insights (immutability enforcement, guard clauses)
   - Process insights (TDD loop efficiency, pipeline optimization)

3. Call MCP tool: extract-session-learnings
   ```json
   {
     "tool": "mcp__contextengineering-mcp__extract-session-learnings",
     "arguments": {
       "workspaceRoot": "/workspace/projects/yourproject",
       "contextScope": "lightsout-task-1.1-1.3",
       "interactionSummary": "Implemented PricePoint value object with TDD. Tests revealed need for explicit timestamp validation. Pipeline integration confirmed domain event serialization works correctly.",
       "insights": [
         {
           "type": "domain",
           "content": "PricePoint immutability enforced via readonly properties and private constructor"
         },
         {
           "type": "technical",
           "content": "Guard clauses prevent invalid state construction, eliminating defensive checks elsewhere"
         }
       ]
     }
   }
   ```

4. Update YAML frontmatter
   ```yaml
   insight_count: 1  # Increment by 1
   ```

**Expected Outcome**: Insights persisted to .context/learnings/, insight_count incremented

**Checkpoint**: Update state block with insight extraction
```

**Loop Protocol**:

```
┌─────────────────────────────────────────────────────────────┐
│ TDD LOOP (Repeat for each logical feature unit)            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. [RED] Write Failing Test                               │
│     ├─ Create test file                                    │
│     ├─ Write test cases (expect failures)                  │
│     ├─ Run tests (verify failures)                         │
│     └─ Commit: "test: ..."                                 │
│                                                             │
│  2. [GREEN] Implement Code                                 │
│     ├─ Create implementation file                          │
│     ├─ Write minimal code to pass tests                    │
│     ├─ Run tests (verify all pass)                         │
│     └─ Commit: "feat: ..."                                 │
│                                                             │
│  3. [TEST] Pipeline Integration (unit tests)               │
│     ├─ Push branch                                         │
│     ├─ Trigger pipeline (capture batch ID)                 │
│     ├─ Poll for completion (max 5 min)                     │
│     ├─ If failed: Query Seq logs with batch ID            │
│     └─ Checkpoint: Record result                           │
│                                                             │
│  4. [INTEGRATION] Cross-Component Verification (NEW v2.4)  │
│     ├─ Identify cross-feature boundaries touched           │
│     ├─ Run integration tests (REAL dependencies, no mocks) │
│     ├─ Write new integration test if new boundary          │
│     ├─ If failed: STOP — fix before proceeding            │
│     └─ Commit: "test(integration): ..."                    │
│                                                             │
│  5. [INSIGHT] Extract Learnings (conditional)              │
│     ├─ Review trigger conditions                           │
│     ├─ If triggered: Call extract-session-learnings       │
│     ├─ Update insight_count                                │
│     └─ Checkpoint: Record extraction                       │
│                                                             │
│  6. Update State Block                                     │
│     ├─ Increment completed_tasks                           │
│     ├─ Calculate test_pass_rate                            │
│     ├─ Update last_checkpoint timestamp                    │
│     └─ Commit state block changes                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Ralph's Principle Compliance**:
- Each task: 100-200 LOC maximum
- Time bound: 10-30 minutes per task
- Fresh context: Each loop starts with clean git state
- Memory via artifacts: Git commits + state blocks + insights

**Checkpoint Template**:
```markdown
## State Block - Task X.Y Complete

**Timestamp**: 2026-01-26T15:45:00Z
**Status**: in_progress
**Execution ID**: abc-123-def-456
**Branch**: lightsout/F999-feature-name-20260126-143000
**Pipeline Batch ID**: 12345
**Completed Tasks**: 4 / 12
**Test Pass Rate**: 100%
**Insight Count**: 1
**Checkpoint**: Task 1.4 complete, PricePoint value object implemented with TDD, insights extracted
**Next Task**: Task 1.5 - Write failing test for PriceCalculator service
```

---

### Phase 2: Refactoring (If Needed)

**Objective**: Improve code structure without changing behavior

**Acceptance Criteria**:
- [ ] All tests still pass after refactoring
- [ ] Code complexity reduced (cyclomatic complexity, nesting depth)
- [ ] Architectural patterns clarified
- [ ] Insights extracted if new patterns emerged

**Task Breakdown**: (Same structure as Phase 1, type: "refactor")

---

### PHASE FINAL: Integration Validation (DAG Checkpoint - MANDATORY)

**Purpose**: This section marks a DAG checkpoint where the lightsout execution engine triggers automated pipeline validation. This is declarative metadata for the execution engine, not a manual task list for AI agents.

**Why This Phase Exists**: The pipeline effectiveness analysis found that 225 passing unit tests and a green pipeline do NOT guarantee a working system. The autonomous orchestrator passed every unit test but failed on its very first real execution (ISSUE-001 through ISSUE-016). "Done" means "works in production," not "unit tests pass." PHASE FINAL provides automated CI/CD integration to catch these issues before human review.

**CRITICAL**: This phase is MANDATORY. It cannot be skipped, deferred, or marked complete without pipeline validation passing. Failure in this phase triggers the Ralph Wiggum pattern (spawn unplanned fix task → retry).

**Execution Model** (NEW in v3.0.1):

**For Execution Engine** (Automated DAG Checkpoint):
- **Checkpoint Detection**: Engine parses `dag_dependencies.nodes[].checkpoint_type` from parent ICP or detects phase completion
- **Pipeline Trigger**: When AI agent reaches PHASE FINAL, engine automatically triggers CI/CD pipeline
- **Wait Strategy**: Engine polls pipeline status (timeout from `pipeline_checkpoints.timeout_minutes`)
- **Failure Handling**: If pipeline fails, engine spawns unplanned fix task (see "Ralph Wiggum Pattern" below)
- **Retry Logic**: Max retries from `pipeline_checkpoints.max_retries`, then escalate to human
- **Success Path**: Pipeline passes → engine updates state blocks → proceeds to next phase/completion

**For AI Agent** (Declarative Reporting):
- This is **NOT a manual task to execute** (no git push, no pipeline triggering, no polling)
- When you reach PHASE FINAL, report: "Phase N complete - DAG checkpoint reached"
- The execution engine handles all pipeline orchestration automatically
- You will receive pipeline results from the engine (pass/fail + logs)
- If pipeline fails and unplanned task spawned, you will receive that task as a new execution context

**Acceptance Criteria**:
- [ ] All phase tasks completed (TDD loops, integration tests, insights extracted)
- [ ] Pipeline validation triggered automatically by execution engine
- [ ] Pipeline passes (all tests green: unit, integration, E2E)
- [ ] No breaking changes to existing functionality
- [ ] Performance benchmarks met (if applicable)
- [ ] State blocks updated with completion metadata

**Ralph Wiggum Pattern** (Integration Failure Recovery):

When pipeline validation fails during PHASE FINAL, the execution engine automatically:
1. Increments retry counter (tracks against `pipeline_checkpoints.max_retries`)
2. Spawns an **unplanned task** with failure context:
   ```yaml
   unplanned_task:
     id: "unplanned-{{timestamp}}"
     title: "Fix integration failure from pipeline run {{run_id}}"
     type: "integration_fix"
     parent_phase: "{{phase_id}}"
     context:
       pipeline_run_id: "{{run_id}}"
       failure_reason: "{{error_message}}"
       failed_tests: ["test1", "test2"]
       log_url: "{{log_url}}"
       retry_count: {{current_retry}}
   ```
3. Launches new AI agent with unplanned task context
4. AI agent reads failure details, fixes the issue, commits the fix
5. Engine retries pipeline validation
6. If retry succeeds → continue to next phase
7. If retry fails and retry_count < max_retries → spawn another unplanned task
8. If retry_count >= max_retries → escalate to human (pause execution)

This pattern embraces **integration failures as expected friction** in autonomous development, not exceptional cases.

**Task Breakdown** (DEPRECATED - For Reference Only):

> **Note**: The task breakdown below is from v3.0.0 and represents the OLD manual execution pattern.
> As of v3.0.1, PHASE FINAL is a DAG checkpoint handled by the execution engine, not manual AI tasks.
> These tasks are preserved for reference in case manual smoke testing is needed outside the pipeline.

```markdown
#### Task FINAL.1: [Test] Execute Real End-to-End Workflow

**Type**: test
**Risk Level**: high
**Requires Approval**: false (autonomous — failure triggers retry/escalation)

**Test Objective**: Run the system with a real input, not test fixtures

**Steps**:
1. Identify a representative real-world input for the feature
   - For an API: make a real API call with realistic data
   - For a service: process a real input from the expected source
   - For a UI: render real data and validate the output

2. Execute the full workflow from entry point to final output
   ```bash
   # Example: Run the system with a real ICP file
   # Adjust for your specific feature's entry point
   ```

3. Validate the complete output
   - All features in the workflow participated (check logs, not just final output)
   - Data flowed correctly between features (no dropped data, no silent failures)
   - Error cases produce visible, actionable errors (not swallowed exceptions)

4. Check for TODO comments that defer integration work
   ```bash
   # Scan for deferred integration work
   grep -rn "TODO.*integration\|TODO.*wire\|TODO.*connect\|TODO.*Phase" src/ || echo "No deferred integration TODOs found"
   ```

**Expected Outcome**: Full workflow completes successfully with real input

**Failure Protocol** (autonomous):
- If workflow fails: capture full error trace, update state block
- Orchestrator attempts diagnosis and fix (max 2 retries)
- If fix fails: status = "paused", escalate to human review
- Do NOT proceed to deployment validation with a broken workflow
```

```markdown
#### Task FINAL.2: [Test] Validate Deployment

**Type**: test
**Risk Level**: high
**Requires Approval**: false

**Test Objective**: Verify the system works when deployed to the target environment

**Steps**:
1. Deploy to target environment
   ```bash
   # Push and trigger deployment pipeline
   git push origin "$BRANCH_NAME"
   DEPLOY_RUN_ID=$(az pipelines run --name "YourPipeline" --branch "$BRANCH_NAME" --query "id" -o tsv)
   # Poll for completion (same as Task X.3)
   ```

2. Run smoke test from deployed environment
   ```bash
   # Verify health endpoint
   curl -sf http://target-host:port/health || echo "FAIL: Health check failed"

   # Verify feature-specific endpoints/tools are available
   # (Adjust for your specific feature)
   ```

3. Execute the same real workflow from Task FINAL.1 against the deployed system
   - Confirm the workflow works in the deployed environment, not just locally

4. Verify no silent failures in deployment logs
   ```bash
   # Check Seq for errors during smoke test
   curl -s "http://ubuntu-devops.lan:5341/api/events?filter=@Timestamp>='$SMOKE_START_TIME'&count=50" \
     -H "X-Seq-ApiKey: $SEQ_ADMIN_PASSWORD" | jq '.Events[] | select(.Level == "Error")'
   ```

**Expected Outcome**: Deployed system passes smoke test, no errors in logs

**Failure Protocol** (autonomous):
- Deployment failure: capture logs, attempt rollback, escalate
- Smoke test failure: capture error trace, compare with local results
- Do NOT proceed to Phase 3 (Completion) with a broken deployment
```

**Phase FINAL State Block**:
```markdown
## State Block - PHASE FINAL Complete

**Timestamp**: [ISO 8601]
**Status**: completed | failed
**Smoke Test Result**: passed | failed
**Real Workflow Executed**: [description of what was tested]
**Deployment Validated**: yes | no
**Deferred Integration TODOs Found**: [count — should be 0]
**Checkpoint**: PHASE FINAL complete, system validated end-to-end, ready for merge
```

---

### Phase 3: Completion

**Objective**: Finalize implementation and prepare for merge

**Acceptance Criteria**:
- [ ] All tasks completed
- [ ] All tests passing (100% pass rate)
- [ ] Pipeline integration tests succeeded
- [ ] Documentation updated
- [ ] Branch ready for merge

**Steps**:

1. **Final Validation**
   ```bash
   # Run full test suite locally
   dotnet test --no-build --verbosity normal

   # Trigger final pipeline run
   FINAL_PIPELINE_RUN_ID=$(az pipelines run --name "YourPipeline" --branch "$BRANCH_NAME" --query "id" -o tsv)

   # Poll for completion
   # (Same polling logic as Task X.3)
   ```

2. **Update Documentation**
   - Update README.md with new feature
   - Update CHANGELOG.md with implementation notes
   - Commit: "docs: Document new feature implementation"

3. **Final State Block**
   ```markdown
   ## State Block - Phase 3 Complete

   **Timestamp**: 2026-01-26T18:00:00Z
   **Status**: completed
   **Execution ID**: abc-123-def-456
   **Branch**: lightsout/F999-feature-name-20260126-143000
   **Pipeline Batch ID**: 12348 (final run)
   **Completed Tasks**: 12 / 12
   **Test Pass Rate**: 100%
   **Insight Count**: 3
   **Checkpoint**: All phases complete, ready for merge
   **Total Execution Time**: 3h 30m
   ```

4. **Update YAML Frontmatter**
   ```yaml
   status: "completed"
   end_time: "2026-01-26T18:00:00Z"
   completed_tasks: 12
   total_tasks: 12
   test_pass_rate: 100.0
   ```

5. **Prepare Merge Instructions**
   ```markdown
   ## Merge Instructions

   **Branch**: lightsout/F999-feature-name-20260126-143000
   **Target**: main
   **Merge Type**: Squash merge recommended (clean history)
   **Final Pipeline Run**: #12348 (succeeded)
   **Insights Captured**: 3 (see .context/learnings/)

   **Merge Command**:
   ```bash
   git checkout main
   git merge --squash lightsout/F999-feature-name-20260126-143000
   git commit -m "feat: Implement F999 feature (lightsout execution)"
   git push origin main
   git branch -d lightsout/F999-feature-name-20260126-143000
   git push origin --delete lightsout/F999-feature-name-20260126-143000
   ```
   ```

---

## ICP Chain Naming Convention (v2.5)

**Status**: Standardized in v2.5.0 (formalizes existing production pattern)

### Naming Pattern Specification

**Parent ICP:**
```
<feature-id>-<feature-name>-parent.autonomous-build.plan.md
```

**Child ICPs:**
```
<feature-id>-<feature-name>-<seq>-<semantic-phase-name>.autonomous-build.plan.md
```

Where:
- `<feature-id>` = Feature identifier (e.g., F099, F042)
- `<feature-name>` = Lowercase, hyphen-separated feature name (e.g., `user-auth`, `payment-gateway`)
- `<seq>` = Zero-padded 3-digit sequence (001, 002, 003, ...)
- `<semantic-phase-name>` = Lowercase, hyphen-separated phase description (e.g., `domain`, `services`, `api`)
- **Note**: Use lowercase `parent` (not `PARENT`) for metadata consistency

### Examples

**Complete Chain:**
```
# Parent
F099-user-auth-parent.autonomous-build.plan.md

# Children
F099-user-auth-001-domain.autonomous-build.plan.md
F099-user-auth-002-services.autonomous-build.plan.md
F099-user-auth-003-api.autonomous-build.plan.md
F099-user-auth-004-integration.autonomous-build.plan.md
F099-user-auth-005-testing.autonomous-build.plan.md
```

**Archival (with timestamp):**
```
20260126-1430-F099-user-auth-parent.autonomous-build.plan.md
20260126-1430-F099-user-auth-001-domain.autonomous-build.plan.md
20260126-1430-F099-user-auth-002-services.autonomous-build.plan.md
(etc.)
```

### Rationale

**Why Hybrid Semantic Pattern:**

1. **Self-Documenting**: Phase purpose immediately visible in filename
   - ❌ `F099-user-auth-001.autonomous-build.plan.md` - What does Phase 1 do?
   - ✅ `F099-user-auth-001-domain.autonomous-build.plan.md` - Domain model phase, clear!

2. **IDE & File Explorer**: Alphabetical sorting works correctly
   - Parent sorts first, then children in execution order

3. **Searchability**: Semantic phase names enable discovery
   - `rg "domain" --glob "*autonomous-build.plan.md"` finds all domain phases
   - Tab completion: `F099-user-auth<TAB>` shows all related phases

4. **Production-Aligned**: Formalizes existing codebase pattern
   - Current production files use `phase-1-core-dashboard.autonomous-build.plan.md`
   - Team already prefers semantic names over pure numbers

5. **Knowledge Graph Integration**: Phase names become semantic nodes
   - Cross-feature learning synthesis by semantic tags
   - Domain clustering across multiple features

6. **Agent Logging**: Enhanced debugging with semantic context
   ```
   [ERROR] Task 2.3 failed in 001-domain phase (clear context)
   vs
   [ERROR] Task 2.3 failed in CHILD001 (no semantic information)
   ```

### Phase Naming Guidelines

**Good Semantic Names** (action-oriented or architectural):
- `domain` - Domain model implementation
- `services` - Application services layer
- `api` - API controllers and endpoints
- `integration` - Integration with existing system
- `testing` - Comprehensive testing phase
- `error-detection` - Error detection logic
- `validation-fixes` - Validation and fixing logic
- `remediation-exec` - Remediation execution logic
- `learning-extraction` - Learning extraction phase

**Avoid** (too generic or positional):
- `phase-1`, `step-2` (use semantic names instead of pure position)
- `setup`, `work`, `misc` (not descriptive enough)
- `implementation`, `execution` (redundant with ICP concept)

### Validation Rules

**Filename Pattern:**
```regex
# Parent ICP
^[A-Z0-9]+-[\w-]+-parent\.lightsout\.icp\.md$

# Child ICP
^[A-Z0-9]+-[\w-]+-\d{3}-[\w-]+\.lightsout\.icp\.md$
```

**Consistency Checks:**
- Parent and all children must share same `<feature-id>-<feature-name>` prefix
- Child sequence numbers must start at 001 and increment (001, 002, 003, ...)
- All children of same parent must use same ICP type (all .autonomous-build.plan.md)

### Migration from Older Patterns

**Backward Compatibility:**
- ✅ Existing `phase-N-semantic-name` patterns remain valid
- ✅ New chains should use standardized `00N-semantic-name` pattern
- ✅ No forced migration of existing chains required

**Rename Script** (if updating existing chain):
```bash
# See scripts/rename-icp-chain.sh for automated renaming
./scripts/rename-icp-chain.sh F099-user-auth
```

---

## ICP Chain Pattern (NEW in v2.2)

### When to Use Chains

**Decision Criteria**:
- **>20 tasks**: Consider using ICP chains
- **>40 tasks**: ICP chains MANDATORY
- **>10,000 LOC**: Consider decomposition even if task count is lower
- **>4 hours estimated**: Recommend chains for better checkpointing

**Single ICP Limits**:
- Context consumption: 100KB+ documents become unwieldy
- Checkpoint granularity: All-or-nothing execution
- Readability: Hard for humans to monitor progress
- Parallelization: Cannot execute phases concurrently

**Chain Pattern Benefits**:
- ✅ Each child ICP stays within context limits (15KB typical)
- ✅ Natural checkpointing at phase boundaries
- ✅ Easier to review individual phases
- ✅ Can manually execute problematic phase if needed
- ✅ Parallelization potential (independent phases)
- ✅ Complies with Ralph's principle at document level

### Parent ICP Structure

**Purpose**: Orchestrator that coordinates child ICPs

**Frontmatter**:
```yaml
---
execution_id: "abc-123-def-456"
icp_type: "parent"
status: "pending"
branch_name: "lightsout/F099-user-auth-20260126-143000"
pipeline_batch_id: ""
last_checkpoint: ""
start_time: ""
end_time: ""
total_tasks: 45  # Sum of all child tasks
completed_tasks: 0
failed_tasks: 0
insight_count: 0
test_pass_rate: 0.0

# Chain-specific fields
child_icps:
  - "F099-user-auth-001-domain.autonomous-build.plan.md"
  - "F099-user-auth-002-services.autonomous-build.plan.md"
  - "F099-user-auth-003-api.autonomous-build.plan.md"
  - "F099-user-auth-004-integration.autonomous-build.plan.md"
  - "F099-user-auth-005-testing.autonomous-build.plan.md"

dependencies:
  sequential: [1, 2, 3]  # Phases 1, 2, 3 must run in order
  parallel: [[4, 5]]     # Phases 4 and 5 can run concurrently
---
```

**Document Content**:
```markdown
# F099 User Authentication System - Parent ICP

## Feature Overview

Implement comprehensive user authentication system with JWT tokens, role-based access control, and session management.

**Total Scope**: 45 tasks across 5 phases

## Phase Breakdown

### Phase 1: Domain Model (12 tasks)
**Child ICP**: F099-user-auth-001-domain.autonomous-build.plan.md
**Dependencies**: None (start phase)
**Deliverables**:
- User aggregate with value objects
- Role and Permission entities
- Domain events for authentication flows
- Unit tests for domain logic

### Phase 2: Application Services (10 tasks)
**Child ICP**: F099-user-auth-002-services.autonomous-build.plan.md
**Dependencies**: Phase 1 (requires domain model)
**Deliverables**:
- AuthenticationService with JWT generation
- AuthorizationService with role checks
- PasswordHashingService
- Integration tests for services

### Phase 3: API Controllers (8 tasks)
**Child ICP**: F099-user-auth-003-api.autonomous-build.plan.md
**Dependencies**: Phase 2 (requires services)
**Deliverables**:
- Login/Logout endpoints
- User registration endpoint
- Password reset endpoints
- API integration tests

### Phase 4: Integration with Existing System (7 tasks)
**Child ICP**: F099-user-auth-004-integration.autonomous-build.plan.md
**Dependencies**: Phase 3 (requires API)
**Deliverables**:
- Middleware for authentication
- Authorization policies
- Database migrations
- End-to-end tests

### Phase 5: Comprehensive Testing (8 tasks)
**Child ICP**: F099-user-auth-005-testing.autonomous-build.plan.md
**Dependencies**: None (can run parallel with Phase 4)
**Deliverables**:
- Security penetration tests
- Performance tests (1000 concurrent logins)
- Load tests
- Documentation

## Integration Checkpoints

### Checkpoint 1: After Phase 1
- [ ] Domain model compiles
- [ ] All unit tests pass
- [ ] Domain events published correctly

### Checkpoint 2: After Phase 2
- [ ] Services compile and integrate with domain
- [ ] Integration tests pass
- [ ] JWT token generation validated

### Checkpoint 3: After Phase 3
- [ ] API endpoints respond correctly
- [ ] Swagger documentation generated
- [ ] API integration tests pass

### Checkpoint 4: After Phases 4 & 5
- [ ] Full system integration complete
- [ ] All end-to-end tests pass
- [ ] Performance benchmarks met
- [ ] Security audit passed

## Final Validation

**Pipeline Integration**:
- Run full regression test suite
- Verify no breaking changes to existing features
- Confirm authentication works across all endpoints

**Documentation**:
- Update README.md with authentication setup
- Generate API documentation
- Create deployment guide

## Archival

When all child ICPs complete:
1. Archive parent ICP with timestamp: `20260126-1430-F099-user-auth-parent.autonomous-build.plan.md`
2. Archive all child ICPs with same timestamp:
   - `20260126-1430-F099-user-auth-001-domain.autonomous-build.plan.md`
   - `20260126-1430-F099-user-auth-002-services.autonomous-build.plan.md`
   - `20260126-1430-F099-user-auth-003-api.autonomous-build.plan.md`
   - `20260126-1430-F099-user-auth-004-integration.autonomous-build.plan.md`
   - `20260126-1430-F099-user-auth-005-testing.autonomous-build.plan.md`
3. Move to `Documentation/WorkInProgress/Implementations/Implemented/`
```

### Child ICP Structure

**Purpose**: Phase executor with 10-15 tasks

**Frontmatter**:
```yaml
---
execution_id: "def-456-ghi-789"  # Unique per child
icp_type: "child"
status: "pending"
branch_name: "lightsout/F099-user-auth-20260126-143000"  # Same as parent
pipeline_batch_id: ""
last_checkpoint: ""
start_time: ""
end_time: ""
total_tasks: 12
completed_tasks: 0
failed_tasks: 0
insight_count: 0
test_pass_rate: 0.0

# Chain-specific fields
parent_icp: "F099-user-auth-parent.autonomous-build.plan.md"
phase_number: 1
---
```

**Document Content**:
```markdown
# F099 User Auth - Phase 1: Domain Model - Child ICP

## Phase Overview

**Parent ICP**: F099-user-auth-parent.autonomous-build.plan.md
**Phase Number**: 1
**Dependencies**: None (start phase)
**Total Tasks**: 12

## Acceptance Criteria
- [ ] User aggregate with email, password hash, roles
- [ ] Value objects: Email, PasswordHash, Username
- [ ] Role and Permission entities
- [ ] Domain events: UserRegistered, UserLoggedIn, PasswordChanged
- [ ] 100% unit test coverage for domain logic

## Tasks

### Task 1.1: [Red] Write Failing Test for Email Value Object
**Type**: red
**Estimated LOC**: 60
**Time Bound**: 15 minutes
**Risk Level**: low
**Requires Approval**: false

**Test Objective**: Validate email format and immutability

**Steps**:
1. Create test file: `tests/Domain/ValueObjects/EmailTests.cs`
2. Write test: `Constructor_WithInvalidFormat_ThrowsArgumentException()`
3. Write test: `Equals_WithSameEmail_ReturnsTrue()`
4. Run test suite (expect failures)

**Expected Outcome**: 2 failing tests

**Checkpoint**: Update state block

### Task 1.2: [Green] Implement Email Value Object
**Type**: green
**Estimated LOC**: 80
**Time Bound**: 20 minutes
**Risk Level**: low
**Requires Approval**: false

**Implementation Objective**: Create immutable Email value object with regex validation

**Steps**:
1. Create class: `src/Domain/ValueObjects/Email.cs`
2. Implement constructor with regex validation
3. Implement `Equals()` and `GetHashCode()`
4. Run tests (expect all pass)

**Expected Outcome**: 2 passing tests

**Checkpoint**: Update state block

### Task 1.3: [Test] Run Pipeline Integration Tests
**Type**: test
**Estimated LOC**: 0
**Time Bound**: 10 minutes
**Risk Level**: medium
**Requires Approval**: false

(Same structure as Phase 1 Test task template)

### Task 1.4: [Insight] Extract Learnings
**Type**: insight
**Estimated LOC**: 0
**Time Bound**: 5 minutes
**Risk Level**: low
**Requires Approval**: false

(Same structure as Phase 1 Insight task template)

### Tasks 1.5 - 1.12: (Continue pattern)
- [Red] PasswordHash value object tests
- [Green] PasswordHash implementation
- [Red] Username value object tests
- [Green] Username implementation
- [Red] User aggregate tests
- [Green] User aggregate implementation
- [Red] Role entity tests
- [Green] Role entity implementation

## Completion Criteria

**When Phase 1 Complete**:
1. Update parent ICP state block (Phase 1 done)
2. Update child ICP status: "completed"
3. Trigger parent ICP checkpoint
4. Notify MCP server to proceed to Phase 2
```

### Dependency Specification

**Sequential Dependencies**:
```yaml
dependencies:
  sequential: [1, 2, 3, 4, 5]  # All phases run in strict order
```

**Parallel Dependencies**:
```yaml
dependencies:
  sequential: [1, 2, 3]  # Phases 1-3 run in order
  parallel: [[4, 5]]     # Phases 4 and 5 can run concurrently after Phase 3
```

**Complex Dependencies**:
```yaml
dependencies:
  sequential: [1, 2]        # Phases 1-2 sequential
  parallel: [[3, 4], [5]]   # After Phase 2: run 3 & 4 in parallel, then 5
```

**Execution Logic**:
1. MCP server reads parent ICP
2. Parses `dependencies` object
3. For sequential phases: execute in order, checkpoint between each
4. For parallel phases: execute concurrently, checkpoint when all complete
5. Update parent ICP `completed_tasks` as sum of all child completions

### Chain Execution Protocol

**MCP Server Detection**:
```typescript
// Pseudo-code for MCP server logic
function detectChain(icpPath: string): boolean {
  const frontmatter = parseYamlFrontmatter(icpPath);
  return frontmatter.icp_type === "parent" && frontmatter.child_icps.length > 0;
}
```

**Sequential Execution**:
```typescript
// Pseudo-code for sequential phase execution
async function executeChain(parentIcpPath: string) {
  const parent = parseIcp(parentIcpPath);

  for (const phaseNum of parent.dependencies.sequential) {
    const childIcpPath = parent.child_icps[phaseNum - 1];

    // Execute child ICP
    await executeChildIcp(childIcpPath);

    // Checkpoint parent
    updateParentCheckpoint(parentIcpPath, phaseNum);
  }

  // Handle parallel phases (if any)
  for (const parallelGroup of parent.dependencies.parallel) {
    await Promise.all(
      parallelGroup.map(phaseNum =>
        executeChildIcp(parent.child_icps[phaseNum - 1])
      )
    );
    updateParentCheckpoint(parentIcpPath, parallelGroup);
  }
}
```

**Parallel Execution**:
```typescript
// Pseudo-code for parallel phase execution
async function executeParallelPhases(parentIcp, parallelGroup) {
  const childPromises = parallelGroup.map(phaseNum => {
    const childIcpPath = parentIcp.child_icps[phaseNum - 1];
    return executeChildIcp(childIcpPath);
  });

  // Wait for all parallel phases to complete
  await Promise.all(childPromises);

  // Checkpoint parent after all parallel phases done
  updateParentCheckpoint(parentIcp.path, parallelGroup);
}
```

**Checkpoint Strategy**:
- **Per-child completion**: Each child ICP checkpoints independently
- **Parent aggregation**: Parent ICP aggregates child metrics (completed_tasks, insight_count, test_pass_rate)
- **Context window management**: Only active child ICP loaded in context
- **Recovery**: If execution interrupted, resume from last completed child phase

**Context Window Management**:
```
Active Phase: Phase 2 (Services)
Context Loaded:
  - Parent ICP frontmatter only (no full content)
  - Current child ICP (F099-user-auth-002-services.autonomous-build.plan.md) full content
  - Accumulated insights from .context/learnings/

NOT Loaded:
  - Completed child ICPs (Phase 1)
  - Future child ICPs (Phases 3-5)
  - Parent ICP full content (only frontmatter for metadata)
```

**Archival Strategy**:
```bash
# When all child ICPs complete, archive together with shared timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M)
ARCHIVE_DIR="Documentation/WorkInProgress/Implementations/Implemented"

# Archive parent
mv "F099-user-auth-parent.autonomous-build.plan.md" \
   "$ARCHIVE_DIR/$TIMESTAMP-F099-user-auth-parent.autonomous-build.plan.md"

# Archive all children with same timestamp
for child in F099-phase*.autonomous-build.plan.md; do
  mv "$child" "$ARCHIVE_DIR/$TIMESTAMP-$child"
done
```

---

## Seq Debugging Integration

**When to Access Seq Logs**:
- ❌ Tests pass locally but fail in pipeline
- ❌ Integration tests fail with external dependencies
- ❌ Performance degradation detected
- ❌ Unexpected exceptions in pipeline logs

**How to Query Seq**:

1. **By Pipeline Batch ID** (primary correlation)
   ```bash
   curl -s "http://ubuntu-devops.lan:5341/api/events?filter=PipelineBatchId='$PIPELINE_RUN_ID'&count=100" \
     -H "X-Seq-ApiKey: $SEQ_ADMIN_PASSWORD" \
     | jq '.Events[] | {timestamp: .Timestamp, level: .Level, message: .MessageTemplate}'
   ```

2. **By Execution ID** (lightsout-specific)
   ```bash
   curl -s "http://ubuntu-devops.lan:5341/api/events?filter=ExecutionId='$EXECUTION_ID'&count=100" \
     -H "X-Seq-ApiKey: $SEQ_ADMIN_PASSWORD" \
     | jq '.Events[] | select(.Level == "Error" or .Level == "Warning")'
   ```

3. **By Time Range** (last 10 minutes)
   ```bash
   START_TIME=$(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%SZ)
   curl -s "http://ubuntu-devops.lan:5341/api/events?filter=@Timestamp>='$START_TIME'&count=100" \
     -H "X-Seq-ApiKey: $SEQ_ADMIN_PASSWORD" \
     | jq '.Events[] | select(.Properties.SourceContext | contains("YourNamespace"))'
   ```

**Seq Integration Checklist**:
- [ ] SEQ_ADMIN_PASSWORD available in pipeline variables
- [ ] ExecutionId logged in all domain events
- [ ] PipelineBatchId propagated from Azure DevOps
- [ ] Structured logging used (not string concatenation)

---

## Workflow Automation Commands

**Branch Creation**:
```bash
BRANCH_NAME="lightsout/F999-feature-name-$(date +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH_NAME"
git push -u origin "$BRANCH_NAME"
```

**Pipeline Trigger**:
```bash
PIPELINE_RUN_ID=$(az pipelines run \
  --name "YourPipeline" \
  --branch "$BRANCH_NAME" \
  --query "id" -o tsv)
echo "Pipeline run ID: $PIPELINE_RUN_ID"
```

**Pipeline Polling** (with timeout):
```bash
TIMEOUT=300  # 5 minutes
ELAPSED=0
while true; do
  STATUS=$(az pipelines runs show --id "$PIPELINE_RUN_ID" --query "status" -o tsv)
  if [[ "$STATUS" == "completed" ]]; then
    RESULT=$(az pipelines runs show --id "$PIPELINE_RUN_ID" --query "result" -o tsv)
    break
  fi
  if (( ELAPSED >= TIMEOUT )); then
    echo "ERROR: Pipeline timeout after $TIMEOUT seconds"
    exit 1
  fi
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

if [[ "$RESULT" != "succeeded" ]]; then
  echo "ERROR: Pipeline failed with result: $RESULT"
  # Query Seq logs for debugging
  curl -s "http://ubuntu-devops.lan:5341/api/events?filter=PipelineBatchId='$PIPELINE_RUN_ID'" \
    -H "X-Seq-ApiKey: $SEQ_ADMIN_PASSWORD" | jq '.Events[] | select(.Level == "Error")'
  exit 1
fi
```

**Branch Merge/Close**:
```bash
git checkout main
git pull origin main
git merge --squash "$BRANCH_NAME"
git commit -m "feat: Implement feature (lightsout execution $EXECUTION_ID)"
git push origin main
git branch -d "$BRANCH_NAME"
git push origin --delete "$BRANCH_NAME"
```

---

## MCP Tool Integration Points

### extract-session-learnings (Workflow MCP)

**When to Call**:
- After each TDD loop (Task X.4)
- When refactoring reveals architectural patterns
- When debugging uncovers domain insights
- When pipeline errors lead to process improvements

**Tool Schema**:
```json
{
  "tool": "mcp__contextengineering-mcp__extract-session-learnings",
  "arguments": {
    "workspaceRoot": "/workspace/projects/yourproject",
    "contextScope": "lightsout-task-X.Y",
    "interactionSummary": "Brief summary of what was done in this loop",
    "insights": [
      {
        "type": "domain|technical|process",
        "content": "Specific learning extracted"
      }
    ]
  }
}
```

**Output**: Insights persisted to `.context/learnings/<timestamp>-lightsout-task-X.Y.json`

### analyze-code-impact (Workflow MCP)

**When to Call**:
- Before starting Phase 1 (understand blast radius)
- When refactoring crosses domain boundaries

**Tool Schema**:
```json
{
  "tool": "mcp__contextengineering-mcp__analyze-code-impact",
  "arguments": {
    "workspaceRoot": "/workspace/projects/yourproject",
    "changedFiles": ["src/Domain/ValueObjects/PricePoint.cs"],
    "changeDescription": "Added new value object for price calculations"
  }
}
```

**Output**: Domain impact analysis, dependency graph

---

## Error Handling

**Pipeline Failure**:
1. Capture pipeline batch ID
2. Query Seq logs for errors
3. Update state block with failure details
4. Pause execution (status: "paused")
5. Escalate to human for review

**Test Failure**:
1. Capture test output
2. Update state block with failure count
3. If Red task: Expected behavior (continue)
4. If Green task: Debug and retry (max 3 attempts)
5. If retry exhausted: Pause and escalate

**MCP Tool Failure**:
1. Log error details to state block
2. Continue execution (non-blocking)
3. Insights may be lost but implementation continues

---

## Template Usage Instructions

**For Autonomous Agents**:
1. Copy this template to project's `Documentation/WorkInProgress/Implementations/`
2. Rename: `<feature-id>-<feature-name>.autonomous-build.plan.md`
3. Fill in YAML frontmatter during Phase 0
4. Fill in `icp_type`: "single" (or use chain pattern if >20 tasks)
5. Follow Phase 1 task breakdown template for feature-specific tasks
6. Execute loop protocol for each task
7. Update state blocks after each checkpoint
8. Complete Phase 3 when all tasks done

**For ICP Chains** (if >20 tasks):
1. Create parent ICP: `<feature-id>-parent.autonomous-build.plan.md`
2. Set `icp_type: "parent"` in frontmatter
3. Define child ICPs in `child_icps` array
4. Specify dependencies (sequential/parallel)
5. Create child ICPs: `<feature-id>-phase<N>-<name>.autonomous-build.plan.md`
6. Set `icp_type: "child"`, `parent_icp`, `phase_number` in each child
7. Execute via MCP tool (auto-detects chain structure)

**For Human Reviewers**:
- Monitor state blocks for progress
- Review insights in `.context/learnings/`
- Check pipeline results in Azure DevOps
- Approve merge when status: "completed"

---

## Version History

**v2.4.0** (2026-02-07):
- Add [Integration] step to TDD loop: Red → Green → Test → **Integration** → Insight
- [Integration] uses real dependencies (no mocks) to catch cross-component failures
- Add mandatory PHASE FINAL: End-to-End Smoke Test before completion
- Smoke test validates real workflow execution and deployment
- Failure in PHASE FINAL blocks merge (cannot be skipped)
- Addresses pipeline effectiveness analysis findings (R3, R4)

**v2.3.0** (2026-02-05):
- Enhanced Phase 0 with project structure validation (greenfield detection)
- Added conditional infrastructure setup tasks for missing projects
- Resolves ISSUE-003: Missing project structure validation gap

**v2.2.0** (2026-01-26):
- Add ICP Chain Pattern for large-scope implementations
- Add `icp_type` frontmatter field (single/parent/child)
- Add chain-specific frontmatter fields (child_icps, parent_icp, phase_number, dependencies)
- Add Parent ICP template with orchestration structure
- Add Child ICP template with phase execution structure
- Add chain execution protocol (sequential/parallel dependencies)
- Add context window management strategy for chains
- Add archival strategy for chains (shared timestamp)
- Document when to use chains (>20 tasks, >40 tasks mandatory)

**v2.1.0** (2026-01-26):
- Initial template for autonomous TDD execution
- Learning extraction integration
- Seq debugging workflow
- Pipeline polling automation
- Ralph's principle compliance

---

## Related Documents

- `LIGHTSOUT-ICP-DESIGN-RATIONALE-V2.2.md` - Design decisions including chain pattern comparison
- `LIGHTSOUT-ICP-CHAIN-EXAMPLE.md` - Complete working example of parent + child ICPs
- `template.guided-build.plan.md` - Human-guided implementation template
- `SEQ-DEBUGGING-WORKFLOW.md` - Comprehensive Seq integration guide
- `.context/README.md` - Learning extraction system documentation
