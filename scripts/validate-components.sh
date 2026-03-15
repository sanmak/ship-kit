#!/usr/bin/env bash
set -euo pipefail

# ShipKit Component Validator
# Validates YAML frontmatter and structure of component files.
#
# Usage:
#   ./scripts/validate-components.sh [commands|skills|agents|rules]
#   ./scripts/validate-components.sh          # validates all

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

FAILURES=0
PASSES=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Check that a YAML frontmatter block contains a given key.
# Usage: frontmatter_has_key <file> <key>
frontmatter_has_key() {
  local file="$1"
  local key="$2"

  # Extract the frontmatter (between first --- and second ---)
  local in_frontmatter=0
  local found=0
  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if [[ "$in_frontmatter" -eq 1 ]]; then
        break
      fi
      in_frontmatter=1
      continue
    fi
    if [[ "$in_frontmatter" -eq 1 ]]; then
      # Match key at start of line followed by a colon
      if [[ "$line" =~ ^${key}: ]]; then
        found=1
      fi
    fi
  done < "$file"

  return $(( found == 1 ? 0 : 1 ))
}

# Check that a file has YAML frontmatter at all (starts with ---)
has_frontmatter() {
  local file="$1"
  local first_line
  first_line="$(head -n 1 "$file")"
  [[ "$first_line" == "---" ]]
}

# Check that a file contains at least one markdown heading (# ...)
has_markdown_heading() {
  local file="$1"
  grep -qE '^#{1,6} ' "$file"
}

# Print PASS
pass() {
  local file="$1"
  local rel
  rel="${file#"${ROOT_DIR}"/}"
  echo "  PASS  ${rel}"
  PASSES=$((PASSES + 1))
}

# Print FAIL with reason
fail() {
  local file="$1"
  local reason="$2"
  local rel
  rel="${file#"${ROOT_DIR}"/}"
  echo "  FAIL  ${rel}  -- ${reason}"
  FAILURES=$((FAILURES + 1))
}

# ---------------------------------------------------------------------------
# Validators per component type
# ---------------------------------------------------------------------------

validate_commands() {
  local dir="${ROOT_DIR}/commands"
  if [[ ! -d "$dir" ]]; then
    echo "[warn] commands/ directory not found, skipping"
    return
  fi

  echo "== commands =="
  for file in "${dir}"/*.md; do
    [[ -f "$file" ]] || continue

    if ! has_frontmatter "$file"; then
      fail "$file" "missing YAML frontmatter"
      continue
    fi

    local ok=1
    if ! frontmatter_has_key "$file" "description"; then
      fail "$file" "frontmatter missing 'description'"
      ok=0
    fi
    if ! frontmatter_has_key "$file" "allowed-tools"; then
      fail "$file" "frontmatter missing 'allowed-tools'"
      ok=0
    fi
    if [[ "$ok" -eq 1 ]]; then
      pass "$file"
    fi
  done
  echo ""
}

validate_directory() {
  local name="$1"
  local dir="${ROOT_DIR}/${name}"

  if [[ ! -d "$dir" ]]; then
    echo "[warn] ${name}/ directory not found, skipping"
    return
  fi

  echo "== ${name} =="
  for file in "${dir}"/*.md; do
    [[ -f "$file" ]] || continue

    if [[ ! -s "$file" ]]; then
      fail "$file" "file is empty"
      continue
    fi

    if ! has_markdown_heading "$file"; then
      fail "$file" "no markdown heading found"
      continue
    fi

    pass "$file"
  done
  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  TARGETS=("commands" "skills" "agents" "rules")
fi

echo "ShipKit Component Validator"
echo "==========================="
echo ""

for target in "${TARGETS[@]}"; do
  case "$target" in
    commands)
      validate_commands
      ;;
    skills|agents|rules)
      validate_directory "$target"
      ;;
    *)
      echo "[error] Unknown component type: ${target}" >&2
      echo "        Valid types: commands, skills, agents, rules" >&2
      FAILURES=$((FAILURES + 1))
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "---"
echo "Results: ${PASSES} passed, ${FAILURES} failed"

if [[ "$FAILURES" -gt 0 ]]; then
  exit 1
fi

exit 0
