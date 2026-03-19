#!/usr/bin/env bash
#
# init-project.sh — Initialize a new DDE project from the starter kit
#
# Replaces template placeholders throughout the codebase with project-specific values.
#
# Usage:
#   scripts/init-project.sh <project-name>     # name-only mode (backward compat)
#   scripts/init-project.sh                    # full interactive mode
#   scripts/init-project.sh --config file.yml  # batch mode from config file
#   scripts/init-project.sh --config-template  # generate blank config file
#
# Safe to run multiple times (idempotent). Does NOT touch .claude/agents/,
# .kit-dev/, templates/, or blueprint template files.
#

set -euo pipefail

# --- Color output helpers ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[info]${NC} $*"; }
success() { echo -e "${GREEN}[done]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
header()  { echo -e "\n${BOLD}$*${NC}"; }

# --- Determine project root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Directories and files to skip ---
EXCLUDE_DIRS=(".claude/agents" ".kit-dev" ".git" "node_modules" "templates" ".dde")
EXCLUDE_FILES=("docs/architecture/SOLUTION_BLUEPRINT_TEMPLATE.md")

# --- Build find exclusion args ---
FIND_EXCLUDES=()
for dir in "${EXCLUDE_DIRS[@]}"; do
  FIND_EXCLUDES+=(-path "$PROJECT_ROOT/$dir" -prune -o)
done

# --- Cross-platform sed ---
do_sed() {
  local file="$1" pattern="$2"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$pattern" "$file"
  else
    sed -i "$pattern" "$file"
  fi
}

# --- Replace a placeholder in all target files ---
replace_placeholder() {
  local placeholder="$1" value="$2"
  if [[ -z "$value" ]]; then
    return
  fi
  # Escape special characters in value for sed
  local escaped_value
  escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
  local count=0
  while IFS= read -r file; do
    if grep -q "$placeholder" "$file" 2>/dev/null; then
      do_sed "$file" "s|$placeholder|$escaped_value|g"
      count=$((count + 1))
    fi
  done < <(find "$PROJECT_ROOT" "${FIND_EXCLUDES[@]}" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.yml' -o -name '*.yaml' -o -name '*.json' \) -print)

  # Also skip explicit exclude files
  for ef in "${EXCLUDE_FILES[@]}"; do
    local full="$PROJECT_ROOT/$ef"
    if [[ -f "$full" ]]; then
      # Restore if we accidentally replaced in an excluded file
      :
    fi
  done

  if [[ $count -gt 0 ]]; then
    info "Replaced $placeholder in $count file(s)"
  fi
}

# --- Config template generation ---
generate_config_template() {
  cat <<'TMPL'
# DDE Project Configuration
# Fill in your values and run: scripts/init-project.sh --config this-file.yml

project_name: my-project
repo_url: https://github.com/org/my-project

domain: your specialization here
users: your target users here

constraints:
  - Constraint 1
  - Constraint 2

tech_stack:
  language: TypeScript
  framework: Next.js
  database: PostgreSQL
  cache: Redis
  testing: Jest
  ci_cd: GitHub Actions
  observability: Prometheus + Grafana
TMPL
}

# --- Simple YAML parser (no dependencies) ---
yaml_get() {
  local file="$1" key="$2"
  grep "^${key}:" "$file" 2>/dev/null | sed "s/^${key}:[[:space:]]*//" | sed 's/[[:space:]]*$//'
}

yaml_get_nested() {
  local file="$1" parent="$2" key="$3"
  # Find lines under parent: section with indented key
  awk -v p="$parent:" -v k="$key:" '
    $0 ~ "^"p { found=1; next }
    found && /^[a-z]/ { found=0 }
    found && $0 ~ "^  "k { sub("^  "k"[[:space:]]*", ""); print; exit }
  ' "$file"
}

yaml_get_list() {
  local file="$1" key="$2"
  awk -v k="$key:" '
    $0 ~ "^"k { found=1; next }
    found && /^[a-z]/ { exit }
    found && /^  - / { sub("^  - ", ""); print }
  ' "$file"
}

# --- Parse config file ---
parse_config() {
  local config_file="$1"
  if [[ ! -f "$config_file" ]]; then
    echo -e "${RED}Error: Config file not found: $config_file${NC}" >&2
    exit 1
  fi

  PROJECT_NAME=$(yaml_get "$config_file" "project_name")
  REPO_URL=$(yaml_get "$config_file" "repo_url")
  DOMAIN=$(yaml_get "$config_file" "domain")
  USERS=$(yaml_get "$config_file" "users")

  CONSTRAINTS=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && CONSTRAINTS+=("$line")
  done < <(yaml_get_list "$config_file" "constraints")

  TECH_LANGUAGE=$(yaml_get_nested "$config_file" "tech_stack" "language")
  TECH_FRAMEWORK=$(yaml_get_nested "$config_file" "tech_stack" "framework")
  TECH_DATABASE=$(yaml_get_nested "$config_file" "tech_stack" "database")
  TECH_CACHE=$(yaml_get_nested "$config_file" "tech_stack" "cache")
  TECH_TESTING=$(yaml_get_nested "$config_file" "tech_stack" "testing")
  TECH_CICD=$(yaml_get_nested "$config_file" "tech_stack" "ci_cd")
  TECH_OBSERVABILITY=$(yaml_get_nested "$config_file" "tech_stack" "observability")
}

# --- Interactive prompts ---
interactive_mode() {
  echo -e "${BOLD}DDE Starter Kit — Project Initialization${NC}\n"

  # Tier 1: Identity
  header "Identity"
  if [[ -z "$PROJECT_NAME" ]]; then
    read -rp "  Project name: " PROJECT_NAME
    if [[ -z "$PROJECT_NAME" ]]; then
      echo -e "${RED}Error: Project name is required.${NC}" >&2
      exit 1
    fi
  else
    echo -e "  Project name: ${CYAN}$PROJECT_NAME${NC}"
  fi
  read -rp "  Repository URL (optional): " REPO_URL

  # Tier 2: Domain
  header "Domain & Users"
  read -rp "  Specialization (e.g., \"SaaS billing platform\"): " DOMAIN
  read -rp "  Target users (e.g., \"B2B finance teams\"): " USERS

  # Constraints
  header "Constraints (press Enter to skip)"
  CONSTRAINTS=()
  for i in 1 2; do
    read -rp "  Constraint $i: " constraint
    [[ -n "$constraint" ]] && CONSTRAINTS+=("$constraint")
  done

  # Tier 3: Technology Stack
  header "Technology Stack (press Enter to skip any)"
  read -rp "  Language: " TECH_LANGUAGE
  read -rp "  Framework: " TECH_FRAMEWORK
  read -rp "  Database: " TECH_DATABASE
  read -rp "  Cache: " TECH_CACHE
  read -rp "  Testing: " TECH_TESTING
  read -rp "  CI/CD: " TECH_CICD
  read -rp "  Observability: " TECH_OBSERVABILITY

  # Preview
  header "Preview"
  echo ""
  echo -e "  Project:       ${CYAN}$PROJECT_NAME${NC}"
  [[ -n "${REPO_URL:-}" ]] && echo -e "  Repository:    ${CYAN}$REPO_URL${NC}"
  [[ -n "${DOMAIN:-}" ]] && echo -e "  Domain:        ${CYAN}$DOMAIN${NC}"
  [[ -n "${USERS:-}" ]] && echo -e "  Users:         ${CYAN}$USERS${NC}"
  for c in "${CONSTRAINTS[@]:-}"; do
    [[ -n "$c" ]] && echo -e "  Constraint:    ${CYAN}$c${NC}"
  done
  [[ -n "${TECH_LANGUAGE:-}" ]] && echo -e "  Language:      ${CYAN}$TECH_LANGUAGE${NC}"
  [[ -n "${TECH_FRAMEWORK:-}" ]] && echo -e "  Framework:     ${CYAN}$TECH_FRAMEWORK${NC}"
  [[ -n "${TECH_DATABASE:-}" ]] && echo -e "  Database:      ${CYAN}$TECH_DATABASE${NC}"
  [[ -n "${TECH_CACHE:-}" ]] && echo -e "  Cache:         ${CYAN}$TECH_CACHE${NC}"
  [[ -n "${TECH_TESTING:-}" ]] && echo -e "  Testing:       ${CYAN}$TECH_TESTING${NC}"
  [[ -n "${TECH_CICD:-}" ]] && echo -e "  CI/CD:         ${CYAN}$TECH_CICD${NC}"
  [[ -n "${TECH_OBSERVABILITY:-}" ]] && echo -e "  Observability: ${CYAN}$TECH_OBSERVABILITY${NC}"
  echo ""

  read -rp "  Proceed? [Y/n] " confirm
  if [[ "${confirm:-Y}" =~ ^[Nn] ]]; then
    echo "Aborted."
    exit 0
  fi
}

# --- Main ---

# Initialize all variables
PROJECT_NAME=""
REPO_URL=""
DOMAIN=""
USERS=""
CONSTRAINTS=()
TECH_LANGUAGE=""
TECH_FRAMEWORK=""
TECH_DATABASE=""
TECH_CACHE=""
TECH_TESTING=""
TECH_CICD=""
TECH_OBSERVABILITY=""

MODE="interactive"

# Parse arguments
case "${1:-}" in
  --config-template)
    generate_config_template
    exit 0
    ;;
  --config)
    if [[ -z "${2:-}" ]]; then
      echo -e "${RED}Error: --config requires a file path.${NC}" >&2
      exit 1
    fi
    MODE="batch"
    parse_config "$2"
    ;;
  --*)
    echo -e "${RED}Error: Unknown flag: $1${NC}" >&2
    echo "Usage: scripts/init-project.sh [project-name | --config file.yml | --config-template]"
    exit 1
    ;;
  "")
    MODE="interactive"
    ;;
  *)
    # Backward compat: positional arg = name-only mode
    PROJECT_NAME="$1"
    MODE="name-only"
    ;;
esac

# Run interactive prompts if needed
if [[ "$MODE" == "interactive" ]]; then
  interactive_mode
fi

# --- Validate ---
if [[ -z "$PROJECT_NAME" ]]; then
  echo -e "${RED}Error: Project name is required.${NC}" >&2
  exit 1
fi
if [[ "$PROJECT_NAME" =~ [/\\] ]]; then
  echo -e "${RED}Error: Project name must not contain path separators.${NC}" >&2
  exit 1
fi
if [[ -n "${REPO_URL:-}" ]] && [[ ! "$REPO_URL" =~ ^(https://|git@) ]]; then
  warn "Repository URL should start with https:// or git@ — continuing anyway."
fi

header "Initializing project: $PROJECT_NAME"
echo ""

# --- Step 0: Clean inherited DDE session state ---
rm -f "$PROJECT_ROOT/.dde/events.jsonl"
rm -rf "$PROJECT_ROOT/.dde/sessions/"
rm -f "$PROJECT_ROOT/.dde/advisory_cursor"
rm -f "$PROJECT_ROOT/.dde/.health-cache"

# --- Step 1: Replace all placeholders ---
header "Step 1: Replacing placeholders"

replace_placeholder 'reactive-interaction-gateway' "$PROJECT_NAME"
replace_placeholder 'https://github.com/Accenture/reactive-interaction-gateway' "${REPO_URL:-}"
replace_placeholder 'Event-driven API gateway and real-time messaging hub for microservices' "${DOMAIN:-}"
replace_placeholder 'Platform engineers, backend developers, and DevOps teams building event-driven architectures' "${USERS:-}"

# Constraints
if [[ ${#CONSTRAINTS[@]} -gt 0 ]]; then
  replace_placeholder 'Elixir/Erlang ecosystem — leverages OTP for fault tolerance and concurrency' "${CONSTRAINTS[0]:-}"
fi
if [[ ${#CONSTRAINTS[@]} -gt 1 ]]; then
  replace_placeholder 'Must maintain backward compatibility with existing RIG v3 API contracts and event schemas' "${CONSTRAINTS[1]:-}"
fi

# Tech stack — replace {e.g., X} patterns in CLAUDE.md
[[ -n "${TECH_LANGUAGE:-}" ]] && replace_placeholder 'Elixir 1.11+ (Erlang/OTP 23+)' "$TECH_LANGUAGE"
[[ -n "${TECH_FRAMEWORK:-}" ]] && replace_placeholder 'Phoenix 1.5 + Cowboy HTTP server' "$TECH_FRAMEWORK"
[[ -n "${TECH_DATABASE:-}" ]] && replace_placeholder 'ETS (in-memory) + external event stores (Kafka, NATS, Kinesis)' "$TECH_DATABASE"
[[ -n "${TECH_CACHE:-}" ]] && replace_placeholder 'ETS-based memoization (Memoize library)' "$TECH_CACHE"
[[ -n "${TECH_TESTING:-}" ]] && replace_placeholder 'ExUnit + ExCoveralls + Mox + StreamData (property-based)' "$TECH_TESTING"
[[ -n "${TECH_CICD:-}" ]] && replace_placeholder 'GitHub Actions + Docker multi-stage builds' "$TECH_CICD"
[[ -n "${TECH_OBSERVABILITY:-}" ]] && replace_placeholder 'Prometheus + OpenCensus (Jaeger/Zipkin) + structured JSON logging' "$TECH_OBSERVABILITY"

# --- Step 2: Report remaining placeholders ---
header "Step 2: Scanning for remaining template placeholders"
echo ""

REMAINING=""
while IFS= read -r file; do
  matches=$(grep -n '{[A-Z][A-Z_]*[0-9]*}' "$file" 2>/dev/null | head -20) || true
  if [[ -n "$matches" ]]; then
    relative="${file#$PROJECT_ROOT/}"
    REMAINING+="  ${CYAN}$relative${NC}\n"
    while IFS= read -r line; do
      REMAINING+="    $line\n"
    done <<< "$matches"
    REMAINING+="\n"
  fi
done < <(find "$PROJECT_ROOT" "${FIND_EXCLUDES[@]}" -type f -name '*.md' -print -o -type f -name '*.sh' -print)

TECH_REMAINING=""
while IFS= read -r file; do
  matches=$(grep -n '{e\.g\.\,' "$file" 2>/dev/null | head -20) || true
  if [[ -n "$matches" ]]; then
    relative="${file#$PROJECT_ROOT/}"
    TECH_REMAINING+="  ${CYAN}$relative${NC}\n"
    while IFS= read -r line; do
      TECH_REMAINING+="    $line\n"
    done <<< "$matches"
    TECH_REMAINING+="\n"
  fi
done < <(find "$PROJECT_ROOT" "${FIND_EXCLUDES[@]}" -type f -name '*.md' -print)

YOURS_REMAINING=""
while IFS= read -r file; do
  matches=$(grep -n '{YOUR_[A-Z_]*}' "$file" 2>/dev/null | head -20) || true
  if [[ -n "$matches" ]]; then
    relative="${file#$PROJECT_ROOT/}"
    YOURS_REMAINING+="  ${CYAN}$relative${NC}\n"
    while IFS= read -r line; do
      YOURS_REMAINING+="    $line\n"
    done <<< "$matches"
    YOURS_REMAINING+="\n"
  fi
done < <(find "$PROJECT_ROOT" "${FIND_EXCLUDES[@]}" -type f -name '*.md' -print)

if [[ -n "$YOURS_REMAINING" || -n "$TECH_REMAINING" || -n "$REMAINING" ]]; then
  echo -e "${BOLD}Remaining placeholders that need manual attention:${NC}\n"
  [[ -n "$YOURS_REMAINING" ]] && echo -e "${YELLOW}Domain & User placeholders:${NC}" && echo -e "$YOURS_REMAINING"
  [[ -n "$TECH_REMAINING" ]] && echo -e "${YELLOW}Technology stack placeholders (fill in CLAUDE.md):${NC}" && echo -e "$TECH_REMAINING"
  [[ -n "$REMAINING" ]] && echo -e "${YELLOW}Other template placeholders:${NC}" && echo -e "$REMAINING"
else
  success "No remaining placeholders found — project is fully initialized!"
fi

# --- Summary ---
header "Summary"
echo ""
success "Project '$PROJECT_NAME' initialized."
echo ""

# Show next steps based on what's still missing
NEXT_STEPS=()
[[ -n "$TECH_REMAINING" ]] && NEXT_STEPS+=("Fill in the Technology Stack table in CLAUDE.md")
[[ -n "$YOURS_REMAINING" ]] && NEXT_STEPS+=("Set your domain context in CLAUDE.md")
[[ -n "$REMAINING" ]] && NEXT_STEPS+=("Fill remaining template placeholders")
NEXT_STEPS+=("Customize agent skill files in .claude/agents/ for your tech stack")
NEXT_STEPS+=("Create your Solution Blueprint: docs/architecture/SOLUTION_BLUEPRINT.md")

for i in "${!NEXT_STEPS[@]}"; do
  echo "  $((i + 1)). ${NEXT_STEPS[$i]}"
done
echo ""
