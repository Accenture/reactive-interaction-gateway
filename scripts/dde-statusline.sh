#!/usr/bin/env bash
# dde-statusline.sh — Claude Code status line for DDE projects
#
# Mirrors the companion TUI's visual language:
#   ● complete (green)  ◐ in progress (yellow)  ○ not started (dim)
#   ⚡ pending gate (orange)  ✓ passed gate (green)
#
# WI-21.7: Added health glyph, contextual alerts, sprint progress fraction
#
# Reads Claude Code session JSON from stdin, overlays DDE project state.

set -uo pipefail

# --- Read Claude Code session data from stdin ---
INPUT=$(cat)

# --- Resolve project dir (from session JSON or fall back to script location) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# --- JSON extraction (jq > python3 > pure bash fallback) ---
json_val() {
    # $1 = jq expression, $2 = default value
    local val
    if command -v jq >/dev/null 2>&1; then
        val=$(echo "$INPUT" | jq -r "$1 // \"$2\"" 2>/dev/null) && { echo "$val"; return; }
    fi
    if command -v python3 >/dev/null 2>&1; then
        val=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
keys = '$1'.replace('.', ' ').split()
# Navigate dotted path (strip jq-style leading dot)
v = d
for k in keys:
    if k == '' or k.startswith('//'):
        continue
    v = v.get(k, {}) if isinstance(v, dict) else {}
print(v if v and v != {} else '$2')
" 2>/dev/null) && { echo "$val"; return; }
    fi
    # Pure bash fallback: simple key extraction (flat keys only)
    local key="${1##*.}"
    key="${key%%[[:space:]]*}"
    val=$(echo "$INPUT" | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\{0,1\}\([^",}]*\)"\{0,1\}.*/\1/p' | head -1)
    echo "${val:-$2}"
}

MODEL=$(json_val '.model.display_name' '?')
CTX_PCT=$(json_val '.context_window.used_percentage' '0')
COST=$(json_val '.cost.total_cost_usd' '0')
LINES_ADDED=$(json_val '.cost.total_lines_added' '0')
LINES_REMOVED=$(json_val '.cost.total_lines_removed' '0')
PROJECT_DIR=$(json_val '.workspace.project_dir' "$PROJECT_ROOT")

# --- Semantic colors (matching Lip Gloss theme) ---
GREEN='\033[38;2;0;204;102m'
YELLOW='\033[38;2;255;204;0m'
RED='\033[38;2;255;68;68m'
CYAN='\033[38;2;0;204;204m'
DIM='\033[38;2;102;102;102m'
ORANGE='\033[38;2;255;136;0m'
WHITE='\033[38;2;255;255;255m'
PURPLE='\033[38;2;120;80;160m'
BOLD='\033[1m'
R='\033[0m'

# --- Context bar (matches TUI progress bar) ---
ctx_bar() {
    local pct=${1:-0}
    local width=12
    local filled=$((pct * width / 100))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=filled; i<width; i++)); do bar+="░"; done

    local color="$GREEN"
    if (( pct > 80 )); then color="$RED"
    elif (( pct > 50 )); then color="$YELLOW"
    fi
    printf "${color}%s${DIM} %d%%${R}" "$bar" "$pct"
}

# --- Quick DDE phase scan (lightweight — no Go binary needed) ---
phase_icon() {
    # $1=phase name, $2=status: complete|progress|none
    case "$2" in
        complete) printf "${GREEN}●${R}" ;;
        progress) printf "${YELLOW}◐${R}" ;;
        *)        printf "${DIM}○${R}" ;;
    esac
}

scan_phases() {
    local root="$1"
    local v="none" c="none" b="none" s="none" bu="none" ve="none"

    # Vision (check both docs/planning/ and .kit-dev/)
    for f in "$root"/docs/planning/VISION*.md "$root"/.kit-dev/VISION*.md; do
        [[ -f "$f" ]] && [[ "$f" != *TEMPLATE* ]] && ! grep -q 'reactive-interaction-gateway' "$f" 2>/dev/null && v="complete" && break
    done

    # Concept
    for f in "$root"/docs/planning/CONCEPT*.md "$root"/.kit-dev/CONCEPT*.md; do
        [[ -f "$f" ]] && [[ "$f" != *TEMPLATE* ]] && ! grep -q 'reactive-interaction-gateway' "$f" 2>/dev/null && c="complete" && break
    done

    # Blueprint
    local has_bp=false has_adr=false
    for f in "$root"/docs/architecture/SOLUTION_BLUEPRINT*.md "$root"/.kit-dev/BLUEPRINT*.md; do
        [[ -f "$f" ]] && [[ "$f" != *TEMPLATE* ]] && has_bp=true && break
    done
    for f in "$root"/docs/architecture/ADR-*.md "$root"/docs/adrs/[0-9]*.md "$root"/.kit-dev/ADR-*.md; do
        [[ -f "$f" ]] && [[ "$f" != *TEMPLATE* ]] && [[ "$f" != *000-template* ]] && has_adr=true && break
    done
    if $has_bp && $has_adr; then b="complete"
    elif $has_bp || $has_adr; then b="progress"
    fi

    # Specification (check both docs/specs/ and .kit-dev/specs/)
    for f in "$root"/docs/specs/SPEC-*.md "$root"/.kit-dev/specs/SPEC-*.md; do
        [[ -f "$f" ]] && grep -q "## Acceptance Criteria\|Scenario:" "$f" 2>/dev/null && s="complete" && break
    done

    # Build (check for Go source, src/, or tools/)
    if [[ -d "$root/src" ]] && [[ -n "$(find "$root/src" -type f ! -name '*.json' ! -name '.git*' -maxdepth 3 2>/dev/null | head -1)" ]]; then
        bu="progress"
    elif [[ -d "$root/tools" ]] && [[ -n "$(find "$root/tools" -name '*.go' -not -path '*/.claude/*' -maxdepth 5 2>/dev/null | head -1)" ]]; then
        bu="progress"
    fi

    # Verify (check for test files in tests/, tools/, or *_test.go)
    if [[ -d "$root/tests" ]] && [[ -n "$(find "$root/tests" -type f \( -name '*test*' -o -name '*spec*' \) -maxdepth 3 2>/dev/null | head -1)" ]]; then
        ve="progress"
    elif [[ -n "$(find "$root/tools" -name '*_test.go' -not -path '*/.claude/*' -maxdepth 5 2>/dev/null | head -1)" ]]; then
        ve="progress"
    fi

    printf "$(phase_icon V $v)$(phase_icon C $c)$(phase_icon B $b)$(phase_icon S $s)$(phase_icon Bu $bu)$(phase_icon Ve $ve)"
}

# --- Health glyph (WI-21.7) ---
# Derives Machine Spirit temper from build state + annotation count
scan_health() {
    local root="$1"
    local cache_dir="$root/.dde"
    local cache_file="$cache_dir/.health-cache"
    local ttl=30  # seconds

    # Check cache freshness
    if [[ -f "$cache_file" ]]; then
        local cache_age
        if [[ "$(uname)" == "Darwin" ]]; then
            cache_age=$(( $(date +%s) - $(stat -f %m "$cache_file") ))
        else
            cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
        fi
        if (( cache_age < ttl )); then
            cat "$cache_file"
            return
        fi
    fi

    # Quick build check (if go project)
    local build_pass=""
    if [[ -f "$root/go.mod" ]] || [[ -f "$root/tools/dde/go.mod" ]]; then
        if [[ -f "$root/tools/dde/go.mod" ]]; then
            (cd "$root/tools/dde" && go build ./... >/dev/null 2>&1) && build_pass="true" || build_pass="false"
        elif [[ -f "$root/go.mod" ]]; then
            (cd "$root" && go build ./... >/dev/null 2>&1) && build_pass="true" || build_pass="false"
        fi
    elif [[ -f "$root/package.json" ]]; then
        if [[ -f "$root/node_modules/.package-lock.json" ]]; then
            build_pass="true"  # Assume OK if deps installed
        fi
    fi

    # Count inscriptions (TODO/FIXME/HACK)
    local inscriptions=0
    if command -v rg >/dev/null 2>&1; then
        inscriptions=$(rg -c '\bTODO\b|\bFIXME\b|\bHACK\b' "$root" --type go --type ts --type js --type py 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
    fi

    # Derive temper glyph
    local glyph
    if [[ "$build_pass" == "false" ]]; then
        glyph="${RED}✖${R}"  # Wrathful
    elif [[ -z "$build_pass" ]] || (( inscriptions >= 20 )); then
        glyph="${ORANGE}!${R}"  # Restless
    elif (( inscriptions < 5 )); then
        glyph="${GREEN}✦${R}"  # Blessed
    else
        glyph="${YELLOW}~${R}"  # Sated
    fi

    # Write cache
    mkdir -p "$cache_dir" 2>/dev/null
    printf "%s" "$glyph" > "$cache_file" 2>/dev/null
    printf "%s" "$glyph"
}

# --- Sprint info with progress fraction (WI-21.7 enrichment) ---
scan_sprint() {
    local root="$1"
    local plan=""

    # Find active delivery plan
    if [[ -f "$root/.kit-dev/DELIVERY_PLAN.md" ]] && grep -q "### Sprint [0-9]" "$root/.kit-dev/DELIVERY_PLAN.md" 2>/dev/null; then
        plan="$root/.kit-dev/DELIVERY_PLAN.md"
    elif [[ -f "$root/docs/planning/DELIVERY_PLAN.md" ]] && grep -q "### Sprint [0-9]" "$root/docs/planning/DELIVERY_PLAN.md" 2>/dev/null; then
        plan="$root/docs/planning/DELIVERY_PLAN.md"
    fi

    if [[ -z "$plan" ]]; then
        printf "${DIM}no sprint${R}"
        return
    fi

    # Extract sprint number from Active Sprint section (not Previous)
    local sprint_num
    sprint_num=$(sed -n '/^## Active Sprint/,/^## /p' "$plan" | grep "^### Sprint " | head -1 | sed 's/### Sprint \([0-9]*\).*/\1/')

    # Count WIs in active sprint section only (between first ### Sprint and next ---)
    local active_section
    active_section=$(sed -n '/^## Active Sprint/,/^## /p' "$plan" 2>/dev/null)

    local total done
    total=$(echo "$active_section" | grep -c "^| WI-" 2>/dev/null | tail -1 || echo 0)
    done=$(echo "$active_section" | grep "| Complete" | grep -c "^| WI-" 2>/dev/null | tail -1 || echo 0)

    local color="$YELLOW"
    if [[ "$done" -eq "$total" ]] && [[ "$total" -gt 0 ]]; then
        color="$GREEN"
    fi

    # Compact format: S21 3/8 (WI-21.7)
    printf "${CYAN}S%s${R} ${color}%s/%s${R}" "$sprint_num" "$done" "$total"
}

# --- Contextual alert (WI-21.7) ---
scan_alert() {
    local root="$1"
    local plan=""

    # Find active delivery plan
    if [[ -f "$root/.kit-dev/DELIVERY_PLAN.md" ]]; then
        plan="$root/.kit-dev/DELIVERY_PLAN.md"
    elif [[ -f "$root/docs/planning/DELIVERY_PLAN.md" ]]; then
        plan="$root/docs/planning/DELIVERY_PLAN.md"
    fi

    if [[ -z "$plan" ]]; then return; fi

    # Check for blocked items
    local blocked
    blocked=$(grep -c "| Blocked" "$plan" 2>/dev/null || true)
    blocked=${blocked:-0}
    if (( blocked > 0 )); then
        printf "${RED}⚠${blocked}blk${R}"
        return
    fi

    # Check for plan staleness (Complete sprint still in Active section)
    local active_status
    active_status=$(sed -n '/^## Active Sprint/,/^## /p' "$plan" | grep "^\*\*Status:\*\*" | head -1 | sed 's/.*\*\*Status:\*\* //')
    if [[ "$active_status" == "Complete" ]]; then
        printf "${ORANGE}⚠stale${R}"
        return
    fi
}

# --- Git state ---
scan_git() {
    local root="$1"
    if ! git --no-optional-locks -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return
    fi
    local branch
    branch=$(git --no-optional-locks -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)
    local dirty=""
    if [[ -n "$(git --no-optional-locks -C "$root" status --porcelain 2>/dev/null)" ]]; then
        dirty="${YELLOW}*${R}"
    fi
    printf "${CYAN}%s${R}%s" "$branch" "$dirty"
}

# --- Journal session count ---
scan_journal() {
    local root="$1"
    local sessions_dir="$root/.dde/sessions"
    if [[ -d "$sessions_dir" ]]; then
        local count
        count=$(find "$sessions_dir" -name 'session-*.md' 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$count" -gt 0 ]]; then
            printf "${DIM}📜${R}${CYAN}%s${R}" "$count"
        fi
    fi
}

# --- Active WI extraction (WI-46.1) ---
scan_active_wi() {
    local root="$1"
    local events="$root/.dde/events.jsonl"
    [[ -f "$events" ]] || return

    # Find the last wi_start that hasn't been followed by a wi_complete
    local last_wi
    if command -v jq >/dev/null 2>&1; then
        last_wi=$(tac "$events" 2>/dev/null | while IFS= read -r line; do
            type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
            if [[ "$type" == "wi_complete" ]]; then
                break  # most recent event was a completion, no active WI
            elif [[ "$type" == "wi_start" ]]; then
                echo "$line" | jq -r '.payload.wi // empty' 2>/dev/null
                break
            fi
        done)
    fi
    if [[ -n "$last_wi" ]]; then
        printf "${BOLD}${YELLOW}%s${R}" "$last_wi"
    fi
}

# --- Beat counter (WI-46.1) ---
scan_beats() {
    local root="$1"
    local events="$root/.dde/events.jsonl"
    [[ -f "$events" ]] || return

    local count=0
    if command -v grep >/dev/null 2>&1; then
        count=$(grep -c '"type"' "$events" 2>/dev/null || echo 0)
    fi
    if [[ "$count" -gt 0 ]]; then
        printf "${DIM}♫${R}${PURPLE}%s${R}" "$count"
    fi
}

# --- Render ---

# Line 1: health │ phases │ sprint │ active WI │ alert │ git │ journal │ beats
HEALTH=$(scan_health "$PROJECT_DIR")
PHASES=$(scan_phases "$PROJECT_DIR")
SPRINT=$(scan_sprint "$PROJECT_DIR")
ACTIVE_WI=$(scan_active_wi "$PROJECT_DIR")
ALERT=$(scan_alert "$PROJECT_DIR")
GIT=$(scan_git "$PROJECT_DIR")
JOURNAL=$(scan_journal "$PROJECT_DIR")
BEATS=$(scan_beats "$PROJECT_DIR")

LINE1="${HEALTH} ${PHASES} ${DIM}│${R} ${SPRINT}"
if [[ -n "$ACTIVE_WI" ]]; then
    LINE1+=" ${ACTIVE_WI}"
fi
if [[ -n "$ALERT" ]]; then
    LINE1+=" ${ALERT}"
fi
if [[ -n "$GIT" ]]; then
    LINE1+=" ${DIM}│${R} ${GIT}"
fi
if [[ -n "$JOURNAL" ]]; then
    LINE1+=" ${DIM}│${R} ${JOURNAL}"
fi
if [[ -n "$BEATS" ]]; then
    LINE1+=" ${BEATS}"
fi

# Line 2: model │ context │ cost │ lines
COST_FMT=$(printf "%.3f" "$COST")
CTX=$(ctx_bar "$CTX_PCT")
DELTA=""
if [[ "$LINES_ADDED" -gt 0 ]] || [[ "$LINES_REMOVED" -gt 0 ]]; then
    DELTA=" ${DIM}│${R} ${GREEN}+${LINES_ADDED}${R}${RED}-${LINES_REMOVED}${R}"
fi

LINE2="${DIM}${MODEL}${R} ${DIM}│${R} ${CTX} ${DIM}│${R} ${DIM}\$${COST_FMT}${R}${DELTA}"

echo -e "$LINE1"
echo -e "$LINE2"
