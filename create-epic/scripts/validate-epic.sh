#!/usr/bin/env bash
# validate-epic.sh — Validate an Agent Epic directory against EPIC spec v0.5.0
#
# Usage: validate-epic.sh <epic-directory>
#
# Checks:
#   - Required files exist (SKILL.md, EPIC.md)
#   - SKILL.md frontmatter and body structure
#   - EPIC.md frontmatter and body sections
#   - state.json reserved fields
#   - plans/ structure and required sections
#   - hooks/ required triggers and format
#   - cron.d/ YAML structure
#   - policy.yml structure
#   - Name validation (lowercase, no consecutive hyphens, etc.)
#   - Log directory exists
#
# Exit codes:
#   0 — all checks passed
#   1 — one or more checks failed
#   2 — usage error

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ERRORS=0
WARNINGS=0
CHECKS=0

pass() {
  CHECKS=$((CHECKS + 1))
  printf "${GREEN}  ✓${RESET} %s\n" "$1"
}

fail() {
  CHECKS=$((CHECKS + 1))
  ERRORS=$((ERRORS + 1))
  printf "${RED}  ✗${RESET} %s\n" "$1"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf "${YELLOW}  ⚠${RESET} %s\n" "$1"
}

section() {
  printf "\n${CYAN}${BOLD}%s${RESET}\n" "$1"
}

# --- Usage ---

if [ $# -lt 1 ]; then
  echo "Usage: validate-epic.sh <epic-directory>"
  echo ""
  echo "Validate an Agent Epic directory against EPIC spec v0.5.0."
  exit 2
fi

EPIC_DIR="$1"

if [ ! -d "$EPIC_DIR" ]; then
  echo "Error: '$EPIC_DIR' is not a directory"
  exit 2
fi

EPIC_DIR=$(cd "$EPIC_DIR" && pwd)
EPIC_NAME=$(basename "$EPIC_DIR")

printf "${BOLD}Validating epic: %s${RESET}\n" "$EPIC_NAME"
printf "Directory: %s\n" "$EPIC_DIR"

# --- Helper: extract YAML frontmatter value ---
# Usage: fm_value <file> <key>
# Returns the value of a top-level YAML key from --- delimited frontmatter
fm_value() {
  local file="$1" key="$2"
  awk -v key="$key" '
    BEGIN { in_fm=0; found=0 }
    /^---$/ { if (!in_fm) { in_fm=1; next } else { exit } }
    in_fm && $0 ~ "^"key":" {
      sub("^"key":[ ]*", "")
      # Strip quotes
      gsub(/^["'\''"]|["'\''"]$/, "")
      print
      found=1
    }
    END { exit found ? 0 : 1 }
  ' "$file" 2>/dev/null
}

# --- Helper: check if file has YAML frontmatter ---
has_frontmatter() {
  local file="$1"
  head -1 "$file" 2>/dev/null | grep -q '^---$'
}

# --- Helper: check markdown has a section heading ---
has_section() {
  local file="$1" heading="$2"
  grep -qi "^##\? ${heading}" "$file" 2>/dev/null
}

# --- Helper: check markdown has exact ## heading ---
has_h2() {
  local file="$1" heading="$2"
  grep -qi "^## ${heading}" "$file" 2>/dev/null
}

# --- Helper: check JSON has a key ---
json_has_key() {
  local file="$1" key="$2"
  grep -q "\"${key}\"" "$file" 2>/dev/null
}

# --- Helper: get JSON string value ---
json_value() {
  local file="$1" key="$2"
  grep "\"${key}\"" "$file" 2>/dev/null | head -1 | sed 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*//' | sed 's/[",]//g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
}

# ============================================================
# 1. NAME VALIDATION
# ============================================================
section "Name validation"

if echo "$EPIC_NAME" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
  pass "Name uses valid characters (lowercase, digits, hyphens)"
else
  fail "Name must use only lowercase letters, digits, and hyphens, cannot start/end with hyphen"
fi

if [ ${#EPIC_NAME} -le 64 ]; then
  pass "Name length OK (${#EPIC_NAME}/64)"
else
  fail "Name exceeds 64 characters (${#EPIC_NAME})"
fi

if echo "$EPIC_NAME" | grep -q '\-\-'; then
  fail "Name contains consecutive hyphens"
else
  pass "No consecutive hyphens in name"
fi

# ============================================================
# 2. REQUIRED FILES
# ============================================================
section "Required files"

if [ -f "$EPIC_DIR/SKILL.md" ]; then
  pass "SKILL.md exists"
else
  fail "SKILL.md is missing (required)"
fi

if [ -f "$EPIC_DIR/EPIC.md" ]; then
  pass "EPIC.md exists"
else
  fail "EPIC.md is missing (required)"
fi

# ============================================================
# 3. SKILL.md VALIDATION
# ============================================================
section "SKILL.md"

if [ -f "$EPIC_DIR/SKILL.md" ]; then
  # Check body sections
  if has_section "$EPIC_DIR/SKILL.md" "Purpose"; then
    pass "Has Purpose section"
  else
    fail "Missing Purpose section"
  fi

  if has_section "$EPIC_DIR/SKILL.md" "Operating loop"; then
    pass "Has Operating loop section"
  else
    fail "Missing Operating loop section"
  fi

  if has_section "$EPIC_DIR/SKILL.md" "Rules"; then
    pass "Has Rules section"
  else
    fail "Missing Rules section"
  fi

  # Check operating loop references state.json
  if grep -q "state.json" "$EPIC_DIR/SKILL.md" 2>/dev/null; then
    pass "Operating loop references state.json"
  else
    warn "Operating loop does not reference state.json"
  fi

  # Check operating loop references log/
  if grep -q "log/" "$EPIC_DIR/SKILL.md" 2>/dev/null; then
    pass "Operating loop references log/"
  else
    warn "Operating loop does not reference log/"
  fi
fi

# ============================================================
# 4. EPIC.md VALIDATION
# ============================================================
section "EPIC.md"

if [ -f "$EPIC_DIR/EPIC.md" ]; then
  # Check frontmatter exists
  if has_frontmatter "$EPIC_DIR/EPIC.md"; then
    pass "Has YAML frontmatter"
  else
    fail "Missing YAML frontmatter (must start with ---)"
  fi

  # Check spec_version
  SPEC_VERSION=$(fm_value "$EPIC_DIR/EPIC.md" "spec_version" || true)
  if [ "$SPEC_VERSION" = "0.5.0" ]; then
    pass "spec_version is 0.5.0"
  elif [ -n "$SPEC_VERSION" ]; then
    warn "spec_version is '$SPEC_VERSION' (expected 0.5.0)"
  else
    fail "Missing spec_version in frontmatter"
  fi

  # Check id
  EPIC_ID=$(fm_value "$EPIC_DIR/EPIC.md" "id" || true)
  if [ -n "$EPIC_ID" ]; then
    if [ "$EPIC_ID" = "$EPIC_NAME" ]; then
      pass "id matches directory name ($EPIC_ID)"
    else
      fail "id '$EPIC_ID' does not match directory name '$EPIC_NAME'"
    fi
  else
    fail "Missing id in frontmatter"
  fi

  # Check required body sections
  for heading in "Objective" "Phases" "Success criteria" "State to preserve" "Guardrails" "Resume"; do
    if has_h2 "$EPIC_DIR/EPIC.md" "$heading"; then
      pass "Has '$heading' section"
    else
      fail "Missing '$heading' section"
    fi
  done
fi

# ============================================================
# 5. STATE.JSON VALIDATION
# ============================================================
section "state.json"

if [ -f "$EPIC_DIR/state.json" ]; then
  pass "state.json exists"

  # Check reserved fields
  for field in state_version status current_plan; do
    if json_has_key "$EPIC_DIR/state.json" "$field"; then
      pass "Has reserved field '$field'"
    else
      fail "Missing reserved field '$field'"
    fi
  done

  # Check status value
  STATUS=$(json_value "$EPIC_DIR/state.json" "status")
  case "$STATUS" in
    active|paused|complete|abandoned)
      pass "Status is valid ('$STATUS')"
      ;;
    *)
      fail "Status '$STATUS' is not valid (must be active|paused|complete|abandoned)"
      ;;
  esac

  # Check valid JSON
  if python3 -c "import json; json.load(open('$EPIC_DIR/state.json'))" 2>/dev/null; then
    pass "Valid JSON"
  else
    fail "Invalid JSON syntax"
  fi
else
  fail "state.json is missing (recommended)"
fi

# ============================================================
# 6. PLANS/ VALIDATION
# ============================================================
section "plans/"

if [ -d "$EPIC_DIR/plans" ]; then
  pass "plans/ directory exists"

  PLAN_COUNT=$(find "$EPIC_DIR/plans" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$PLAN_COUNT" -gt 0 ]; then
    pass "Contains $PLAN_COUNT plan file(s)"

    # Validate each plan
    while IFS= read -r plan_file; do
      plan_name=$(basename "$plan_file")

      # Check required sections
      has_now=false has_next=false has_blocked=false has_updated=false

      if has_h2 "$plan_file" "Now"; then has_now=true; fi
      if has_h2 "$plan_file" "Next"; then has_next=true; fi
      if has_h2 "$plan_file" "Blocked"; then has_blocked=true; fi
      if grep -qi "^Updated:" "$plan_file" 2>/dev/null; then has_updated=true; fi

      if $has_now && $has_next && $has_blocked; then
        pass "$plan_name has Now, Next, and Blocked sections"
      else
        missing=""
        $has_now || missing="${missing}Now, "
        $has_next || missing="${missing}Next, "
        $has_blocked || missing="${missing}Blocked, "
        missing=${missing%, }
        fail "$plan_name missing sections: $missing"
      fi

      if $has_updated; then
        pass "$plan_name has Updated: line"
      else
        warn "$plan_name missing Updated: line"
      fi
    done < <(find "$EPIC_DIR/plans" -name '*.md' -type f 2>/dev/null)
  else
    fail "plans/ has no .md files"
  fi
else
  fail "plans/ directory is missing (recommended)"
fi

# ============================================================
# 7. LOG/ VALIDATION
# ============================================================
section "log/"

if [ -d "$EPIC_DIR/log" ]; then
  pass "log/ directory exists"
else
  fail "log/ directory is missing (recommended)"
fi

# ============================================================
# 8. HOOKS/ VALIDATION
# ============================================================
section "hooks/"

if [ -d "$EPIC_DIR/hooks" ]; then
  pass "hooks/ directory exists"

  # Check for install hook
  if [ -f "$EPIC_DIR/hooks/install.md" ] || [ -d "$EPIC_DIR/hooks/install.d" ]; then
    pass "Has install hook"
  else
    fail "Missing install hook (install.md or install.d/)"
  fi

  # Check for status-changed hook
  if [ -f "$EPIC_DIR/hooks/status-changed.md" ] || [ -d "$EPIC_DIR/hooks/status-changed.d" ]; then
    pass "Has status-changed hook"
  else
    fail "Missing status-changed hook (status-changed.md or status-changed.d/)"
  fi

  # Validate each hook file
  while IFS= read -r hook_file; do
    hook_name=$(basename "$hook_file")

    if has_frontmatter "$hook_file"; then
      pass "$hook_name has YAML frontmatter"

      # Check type field
      HOOK_TYPE=$(fm_value "$hook_file" "type" || true)
      case "$HOOK_TYPE" in
        prompt|script|http|agent)
          pass "$hook_name type is valid ('$HOOK_TYPE')"
          ;;
        "")
          fail "$hook_name missing type field in frontmatter"
          ;;
        *)
          fail "$hook_name has invalid type '$HOOK_TYPE' (must be prompt|script|http|agent)"
          ;;
      esac

      # Check enabled field
      HOOK_ENABLED=$(fm_value "$hook_file" "enabled" || true)
      if [ -n "$HOOK_ENABLED" ]; then
        pass "$hook_name has enabled field"
      else
        warn "$hook_name missing enabled field (defaults to true)"
      fi

      # Check timeout field
      HOOK_TIMEOUT=$(fm_value "$hook_file" "timeout" || true)
      if [ -n "$HOOK_TIMEOUT" ]; then
        pass "$hook_name has timeout ($HOOK_TIMEOUT s)"
      else
        warn "$hook_name missing timeout field"
      fi
    else
      fail "$hook_name missing YAML frontmatter"
    fi

    # Check that hook has body content after frontmatter
    BODY_LINES=$(awk '/^---$/ { count++; next } count >= 2 { lines++ } END { print lines+0 }' "$hook_file" 2>/dev/null)
    if [ "$BODY_LINES" -gt 0 ]; then
      pass "$hook_name has prompt body ($BODY_LINES lines)"
    else
      fail "$hook_name has no prompt body after frontmatter"
    fi
  done < <(find "$EPIC_DIR/hooks" -name '*.md' -type f 2>/dev/null)

  # Validate canonical trigger names
  while IFS= read -r hook_file; do
    hook_name=$(basename "$hook_file" .md)
    case "$hook_name" in
      install|uninstall|status-changed|milestone-complete|plan-empty|became-blocked|cron-fired)
        # Known canonical trigger
        ;;
      *)
        warn "Hook '$hook_name' is not a canonical trigger name"
        ;;
    esac
  done < <(find "$EPIC_DIR/hooks" -name '*.md' -type f 2>/dev/null)
else
  fail "hooks/ directory is missing (recommended for operational epics)"
fi

# ============================================================
# 9. CRON.D/ VALIDATION
# ============================================================
section "cron.d/"

if [ -d "$EPIC_DIR/cron.d" ]; then
  pass "cron.d/ directory exists"

  CRON_COUNT=$(find "$EPIC_DIR/cron.d" -name '*.yml' -o -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$CRON_COUNT" -gt 0 ]; then
    pass "Contains $CRON_COUNT cron file(s)"

    while IFS= read -r cron_file; do
      cron_name=$(basename "$cron_file")

      # Check required fields
      for field in name schedule enabled; do
        if grep -q "^${field}:" "$cron_file" 2>/dev/null; then
          pass "$cron_name has '$field' field"
        else
          fail "$cron_name missing '$field' field"
        fi
      done

      # Check run section
      if grep -q "^run:" "$cron_file" 2>/dev/null; then
        pass "$cron_name has 'run' section"

        # Check run.type
        RUN_TYPE=$(grep '  type:' "$cron_file" 2>/dev/null | head -1 | sed 's/.*type:[[:space:]]*//' | tr -d '"' | tr -d "'")
        case "$RUN_TYPE" in
          prompt|script|both)
            pass "$cron_name run.type is valid ('$RUN_TYPE')"
            ;;
          "")
            fail "$cron_name missing run.type"
            ;;
          *)
            fail "$cron_name has invalid run.type '$RUN_TYPE' (must be prompt|script|both)"
            ;;
        esac
      else
        fail "$cron_name missing 'run' section"
      fi

      # Check output section
      if grep -q "^output:" "$cron_file" 2>/dev/null; then
        pass "$cron_name has 'output' section"
      else
        warn "$cron_name missing 'output' section"
      fi

      # Check schedule is valid cron expression
      SCHEDULE=$(grep '^schedule:' "$cron_file" 2>/dev/null | head -1 | sed 's/^schedule:[[:space:]]*//' | tr -d '"' | tr -d "'")
      if [ -n "$SCHEDULE" ]; then
        FIELD_COUNT=$(echo "$SCHEDULE" | awk '{print NF}')
        if [ "$FIELD_COUNT" -eq 5 ]; then
          pass "$cron_name schedule has 5 fields ('$SCHEDULE')"
        else
          fail "$cron_name schedule '$SCHEDULE' does not have 5 fields (has $FIELD_COUNT)"
        fi
      fi
    done < <(find "$EPIC_DIR/cron.d" -name '*.yml' -o -name '*.yaml' 2>/dev/null)
  else
    warn "cron.d/ has no .yml files"
  fi
else
  warn "cron.d/ directory not present (optional — skip for manual-only epics)"
fi

# ============================================================
# 10. POLICY.YML VALIDATION
# ============================================================
section "policy.yml"

if [ -f "$EPIC_DIR/policy.yml" ]; then
  pass "policy.yml exists"

  # Check autonomy section
  if grep -q "^autonomy:" "$EPIC_DIR/policy.yml" 2>/dev/null; then
    pass "Has 'autonomy' section"

    if grep -q "max_spend_per_run:" "$EPIC_DIR/policy.yml" 2>/dev/null; then
      SPEND=$(grep "max_spend_per_run:" "$EPIC_DIR/policy.yml" | head -1 | sed 's/.*max_spend_per_run:[[:space:]]*//')
      pass "Has max_spend_per_run ($SPEND)"
    else
      warn "Missing max_spend_per_run in autonomy section"
    fi

    if grep -q "allowed_tools:" "$EPIC_DIR/policy.yml" 2>/dev/null; then
      pass "Has allowed_tools list"
    else
      warn "Missing allowed_tools in autonomy section"
    fi

    if grep -q "forbidden_actions:" "$EPIC_DIR/policy.yml" 2>/dev/null; then
      pass "Has forbidden_actions list"
    else
      warn "Missing forbidden_actions in autonomy section"
    fi
  else
    fail "Missing 'autonomy' section"
  fi

  # Check escalation section
  if grep -q "^escalation:" "$EPIC_DIR/policy.yml" 2>/dev/null; then
    pass "Has 'escalation' section"

    if grep -q "on_error:" "$EPIC_DIR/policy.yml" 2>/dev/null; then
      ON_ERROR=$(grep "on_error:" "$EPIC_DIR/policy.yml" | head -1 | sed 's/.*on_error:[[:space:]]*//')
      pass "Has on_error ($ON_ERROR)"
    else
      warn "Missing on_error in escalation section"
    fi

    if grep -q "on_ambiguity:" "$EPIC_DIR/policy.yml" 2>/dev/null; then
      ON_AMB=$(grep "on_ambiguity:" "$EPIC_DIR/policy.yml" | head -1 | sed 's/.*on_ambiguity:[[:space:]]*//')
      pass "Has on_ambiguity ($ON_AMB)"
    else
      warn "Missing on_ambiguity in escalation section"
    fi
  else
    fail "Missing 'escalation' section"
  fi
else
  fail "policy.yml is missing (recommended for operational epics)"
fi

# ============================================================
# 11. CROSS-FILE CONSISTENCY
# ============================================================
section "Cross-file consistency"

# Check that current_plan in state.json points to an existing file
if [ -f "$EPIC_DIR/state.json" ] && [ -d "$EPIC_DIR/plans" ]; then
  CURRENT_PLAN=$(json_value "$EPIC_DIR/state.json" "current_plan")
  if [ -n "$CURRENT_PLAN" ] && [ "$CURRENT_PLAN" != "null" ]; then
    if [ -f "$EPIC_DIR/plans/$CURRENT_PLAN" ]; then
      pass "current_plan '$CURRENT_PLAN' exists in plans/"
    else
      fail "current_plan '$CURRENT_PLAN' does not exist in plans/"
    fi
  fi
fi

# Check that EPIC.md id matches SKILL.md context
if [ -f "$EPIC_DIR/EPIC.md" ] && [ -f "$EPIC_DIR/SKILL.md" ]; then
  # Both exist — check they reference consistent state files
  EPIC_REFS_STATE=$(grep -c "state.json\|state/" "$EPIC_DIR/EPIC.md" 2>/dev/null || true)
  SKILL_REFS_STATE=$(grep -c "state.json\|state/" "$EPIC_DIR/SKILL.md" 2>/dev/null || true)
  if [ "$EPIC_REFS_STATE" -gt 0 ] && [ "$SKILL_REFS_STATE" -gt 0 ]; then
    pass "Both EPIC.md and SKILL.md reference state"
  elif [ "$EPIC_REFS_STATE" -eq 0 ] && [ "$SKILL_REFS_STATE" -eq 0 ]; then
    warn "Neither EPIC.md nor SKILL.md references state"
  else
    warn "State references inconsistent between EPIC.md and SKILL.md"
  fi
fi

# ============================================================
# SUMMARY
# ============================================================
printf "\n${BOLD}━━━ Summary ━━━${RESET}\n"
printf "Epic:     %s\n" "$EPIC_NAME"
printf "Checks:   %d\n" "$CHECKS"
printf "${GREEN}Passed:   %d${RESET}\n" "$((CHECKS - ERRORS))"
if [ "$ERRORS" -gt 0 ]; then
  printf "${RED}Failed:   %d${RESET}\n" "$ERRORS"
fi
if [ "$WARNINGS" -gt 0 ]; then
  printf "${YELLOW}Warnings: %d${RESET}\n" "$WARNINGS"
fi

if [ "$ERRORS" -eq 0 ]; then
  printf "\n${GREEN}${BOLD}Epic is valid.${RESET}\n"
  exit 0
else
  printf "\n${RED}${BOLD}Epic has %d error(s). Fix the issues above.${RESET}\n" "$ERRORS"
  exit 1
fi
