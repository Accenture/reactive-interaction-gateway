---
description: Pull request review. Collaborative by default, fully autonomous with --auto. Checks ADR compliance, code quality, security, and project conventions.
argument-hint: "[PR number] [--auto]"
model: inherit
---

# PR Review

PR: $ARGUMENTS

Parse arguments: PR number is the integer, `--auto` flag enables autonomous mode.

## Mode

**Collaborative** (default): Pause at checkpoints, discuss findings, build recommendation together.

**Autonomous** (`--auto`): Run the full review without pausing. Collect all findings. Post a complete structured review to the PR at the end. No user input required.

In autonomous mode: skip all "CHECKPOINT" instructions. Collect findings into a running list. Post the final review as a GitHub PR comment at the end.

---

## Setup

```bash
gh pr view $PR_NUMBER --json \
  number,title,author,headRefName,baseRefName,body,additions,deletions,changedFiles,state,isDraft

gh pr diff $PR_NUMBER --name-only

git fetch origin
git diff origin/main...origin/$(gh pr view $PR_NUMBER --json headRefName -q .headRefName) --stat
```

**Present:**
- PR title, author, branch, status, description
- File count, +/- lines
- File type breakdown by language/purpose
- Auto-detect change areas based on project directory structure

**CHECKPOINT #1** (collaborative only): "Ready to check merge status?"

---

## Merge Status

```bash
git rev-list --left-right --count origin/main...origin/[source-branch]
```

Flag if PR is behind main. Show impacted files. Recommend update if conflicts likely.

**CHECKPOINT #2** (collaborative only): Option A (pause for update) / B (review as-is) / C (investigate).

---

## Automated Checks (run silently, collect findings)

Run these in full before any checkpoint in autonomous mode, or per-section in collaborative.

### 1. ADR Compliance

Check changed code against relevant ADRs in `docs/architecture/`:
- Read the ADR files relevant to the changed areas
- Verify constraints and decisions are respected
- Flag any violations

### 2. Directory Structure

- Check new files follow existing project conventions
- Verify new modules/services mirror established layout patterns
- Flag any new top-level directories without justification

### 3. Code Quality

For each changed file:
- Does it have appropriate tests?
- Does it follow project logging conventions?
- Are error paths handled?
- Does the code match project style/patterns?

### 4. Security

- No hardcoded secrets (grep for `password =`, `api_key =`, `private_key =` as literals)
- No overly broad permissions
- No JSON key files or credentials
- Input validation at API boundaries

### 5. Spec Compliance

If the PR implements a feature:
- Does a spec exist in `docs/specs/`?
- Are acceptance criteria addressed?
- Flag any undocumented behavior

---

## Review Areas (collaborative mode — per-section discussion)

Based on changed files, organise findings into areas. For each:

1. Announce area + files
2. Read relevant files
3. Share findings: what changed, good points, concerns
4. **CHECKPOINT**: "What do you think? Anything to dig into?"

---

## Summary & Recommendation

```markdown
## PR Review: #[NUMBER] — [Title]

### Automated Gate Results
- ADR compliance: Pass/Warn [which ADRs]
- Directory structure: Pass/Warn
- Security scan: Pass/Warn
- Test coverage: Pass/Warn
- Spec compliance: Pass/Warn/N/A

### Findings

**Blocking (must fix before merge):**
- [finding] — ADR violation / security / convention breach

**Non-blocking (recommend fixing):**
- [finding]

**Suggestions:**
- [optional improvements]

### Recommendation
[Approve / Approve with suggestions / Request changes]

[Rationale]
```

**CHECKPOINT #9** (collaborative): "What's your take? What concerns you most?"

---

## Post Review

**Collaborative**: Ask if user wants to post to GitHub.

**Autonomous**: Always post. Use `--approve`, `--request-changes`, or `--comment` based on findings.

```bash
# Approve
gh pr review $PR_NUMBER \
  --approve --body "[review markdown]"

# Request changes
gh pr review $PR_NUMBER \
  --request-changes --body "[review markdown]"

# Comment only
gh pr review $PR_NUMBER \
  --comment --body "[review markdown]"
```

**If blocking issues found**: Create GitHub issues.

```bash
gh issue create \
  --title "[Short title]" \
  --body "## Context\nFrom PR review: #$PR_NUMBER\n\n## Issue\n[detail]\n\n## Action items\n- [ ] [task]" \
  --label "pr-review"
```

---

## Key Principles

**DO:**
- Run automated checks first — they're non-negotiable gates
- Read ADR constraint blocks directly, not from memory
- In autonomous mode: collect everything, post once at the end

**DON'T:**
- Skip security checks for any PR
- Approve if ADR constraints are violated
- Read all files at once — read lazily per area
