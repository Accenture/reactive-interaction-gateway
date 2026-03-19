#!/usr/bin/env bash
# dde-status.sh — Zero-dependency DDE project status
# Works everywhere: no Go, no Node, just ANSI.

set -euo pipefail

ROOT="${1:-.}"

# Colors (respects NO_COLOR)
if [[ -z "${NO_COLOR:-}" ]] && [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    DIM='\033[0;90m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN='' YELLOW='' RED='' CYAN='' DIM='' BOLD='' RESET=''
fi

echo -e "${BOLD}DDE Project Status${RESET}"
echo ""

# --- Session Mode ---
MODE="Unknown"
if [[ -f "$ROOT/.kit-dev/DELIVERY_PLAN.md" ]] && grep -q "### Sprint [0-9]" "$ROOT/.kit-dev/DELIVERY_PLAN.md" 2>/dev/null; then
    MODE="Kit Improvement"
fi
if [[ -f "$ROOT/docs/planning/DELIVERY_PLAN.md" ]] && grep -q "### Sprint [0-9]" "$ROOT/docs/planning/DELIVERY_PLAN.md" 2>/dev/null; then
    if [[ "$MODE" == "Unknown" ]]; then
        MODE="Project Build"
    fi
fi
echo -e "${CYAN}Mode:${RESET} $MODE"
echo ""

# --- Phase Detection ---
echo -e "${BOLD}${CYAN}Phases${RESET}"

check_phase() {
    local name="$1" status="Not Started" icon="○" color="$DIM"
    shift
    # Remaining args are the check conditions
    if "$@" 2>/dev/null; then
        status="Complete" icon="●" color="$GREEN"
    fi
    printf "  %b%s %s%b\n" "$color" "$icon" "$name" "$RESET"
}

# Vision
has_vision() {
    for f in "$ROOT"/docs/planning/VISION*.md; do
        [[ -f "$f" ]] && [[ "$f" != *TEMPLATE* ]] && \
        ! grep -q 'reactive-interaction-gateway\|{YOUR_' "$f" 2>/dev/null && return 0
    done
    return 1
}

# Concept
has_concept() {
    for f in "$ROOT"/docs/planning/CONCEPT*.md; do
        [[ -f "$f" ]] && [[ "$f" != *TEMPLATE* ]] && \
        ! grep -q 'reactive-interaction-gateway\|{YOUR_' "$f" 2>/dev/null && return 0
    done
    return 1
}

# Blueprint
has_blueprint() {
    local found=0
    for f in "$ROOT"/docs/architecture/SOLUTION_BLUEPRINT*.md; do
        [[ -f "$f" ]] && [[ "$f" != *TEMPLATE* ]] && found=1 && break
    done
    [[ $found -eq 0 ]] && return 1
    for f in "$ROOT"/docs/architecture/ADR-*.md; do
        [[ -f "$f" ]] && [[ "$f" != *TEMPLATE* ]] && return 0
    done
    return 1
}

# Specification
has_spec() {
    for f in "$ROOT"/docs/specs/SPEC-*.md; do
        [[ -f "$f" ]] && grep -q "## Acceptance Criteria\|Scenario:" "$f" 2>/dev/null && return 0
    done
    return 1
}

# Build
has_build() {
    [[ -d "$ROOT/src" ]] && find "$ROOT/src" -type f ! -name '*.json' ! -name '*.lock' ! -name '.git*' | head -1 | grep -q .
}

# Verify
has_verify() {
    [[ -d "$ROOT/tests" ]] && find "$ROOT/tests" -type f -name '*test*' -o -name '*spec*' 2>/dev/null | head -1 | grep -q .
}

check_phase "Vision"        has_vision
check_phase "Concept"       has_concept
check_phase "Blueprint"     has_blueprint
check_phase "Specification" has_spec
check_phase "Build"         has_build
check_phase "Verify"        has_verify

echo ""

# --- Sprint Summary ---
PLAN=""
if [[ "$MODE" == "Kit Improvement" ]]; then
    PLAN="$ROOT/.kit-dev/DELIVERY_PLAN.md"
elif [[ "$MODE" == "Project Build" ]]; then
    PLAN="$ROOT/docs/planning/DELIVERY_PLAN.md"
fi

if [[ -n "$PLAN" ]] && [[ -f "$PLAN" ]]; then
    # Detect format: V2 (YAML frontmatter) vs V1 (pure markdown)
    if head -1 "$PLAN" | grep -q '^---$'; then
        # V2: extract YAML frontmatter fields with sed
        FRONTMATTER=$(sed -n '2,/^---$/p' "$PLAN" | sed '$d')
        SPRINT_NUM=$(echo "$FRONTMATTER" | grep '  number:' | head -1 | sed 's/.*number: *//')
        SPRINT_TITLE=$(echo "$FRONTMATTER" | grep '  title:' | head -1 | sed 's/.*title: *"*//' | sed 's/"*$//')
        STATUS=$(echo "$FRONTMATTER" | grep '  status:' | head -1 | sed 's/.*status: *//')
        TESTS=$(echo "$FRONTMATTER" | grep '  tests:' | head -1 | sed 's/.*tests: *//')

        if [[ -n "$SPRINT_NUM" ]]; then
            echo -e "${BOLD}${CYAN}Sprint${RESET}"
            echo -e "  Sprint ${SPRINT_NUM}: ${SPRINT_TITLE}"

            if [[ "$STATUS" == "Complete" ]]; then
                echo -e "  Status: ${GREEN}${STATUS}${RESET}"
            else
                echo -e "  Status: ${YELLOW}${STATUS}${RESET}"
            fi

            # WI counts from markdown body (after frontmatter)
            BODY=$(sed '1,/^---$/{ /^---$/!d; /^---$/!d; }' "$PLAN" | sed '1,/^---$/d')
            TOTAL=$(echo "$BODY" | grep -c "^| WI-" 2>/dev/null || echo 0)
            DONE=$(echo "$BODY" | grep "| Complete" | grep -c "^| WI-" 2>/dev/null || echo 0)
            echo -e "  Items: ${DONE}/${TOTAL}"
            if [[ -n "$TESTS" ]]; then
                echo -e "  Tests: ${TESTS}"
            fi
        fi
    else
        # V1: existing grep/sed parsing (unchanged)
        SPRINT_LINE=$(grep "^### Sprint " "$PLAN" | head -1)
        if [[ -n "$SPRINT_LINE" ]]; then
            echo -e "${BOLD}${CYAN}Sprint${RESET}"
            echo -e "  ${SPRINT_LINE#\#\#\# }"

            STATUS=$(grep "^\*\*Status:\*\*" "$PLAN" | head -1 | sed 's/\*\*Status:\*\* //')
            if [[ "$STATUS" == "Complete" ]]; then
                echo -e "  Status: ${GREEN}${STATUS}${RESET}"
            else
                echo -e "  Status: ${YELLOW}${STATUS}${RESET}"
            fi

            TOTAL=$(grep -c "^| WI-" "$PLAN" 2>/dev/null || echo 0)
            DONE=$(grep "| Complete" "$PLAN" | grep -c "^| WI-" 2>/dev/null || echo 0)
            echo -e "  Items: ${DONE}/${TOTAL}"
        fi
    fi
    echo ""
fi

# --- Process Health ---
KAIZEN_PATH=""
if [[ "$MODE" == "Kit Improvement" ]]; then
    KAIZEN_PATH="$ROOT/.kit-dev/KAIZEN_BACKLOG.md"
elif [[ "$MODE" == "Project Build" ]]; then
    KAIZEN_PATH="$ROOT/docs/planning/KAIZEN_BACKLOG.md"
fi

if [[ -n "$KAIZEN_PATH" ]] && [[ -f "$KAIZEN_PATH" ]]; then
    ACTIVE=$(grep -c "^| K-" "$KAIZEN_PATH" 2>/dev/null || echo 0)
    echo -e "${BOLD}${CYAN}Process Health${RESET}"
    echo -e "  Kaizen: ${ACTIVE} active items"
fi

# --- Git ---
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)
    DIRTY=""
    if [[ -n "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ]]; then
        DIRTY="${YELLOW}Dirty${RESET}"
    else
        DIRTY="${GREEN}Clean${RESET}"
    fi
    echo ""
    echo -e "${BOLD}${CYAN}Git${RESET}"
    echo -e "  Branch: ${CYAN}${BRANCH}${RESET}  ${DIRTY}"
fi
