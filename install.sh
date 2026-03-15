#!/usr/bin/env bash
set -euo pipefail

# ShipKit Installer
# Installs ShipKit components as a Claude Code plugin.
#
# Usage:
#   ./install.sh [--scope user|project]
#
# Scope:
#   user    -> installs to ~/.claude/commands/
#   project -> installs to .claude/commands/ (default)

SCOPE="project"

usage() {
  echo "Usage: $0 [--scope user|project]"
  echo ""
  echo "Options:"
  echo "  --scope user     Install to ~/.claude/commands/ (user-wide)"
  echo "  --scope project  Install to .claude/commands/  (default)"
  exit 1
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --scope requires a value (user or project)" >&2
        usage
      fi
      SCOPE="$2"
      if [[ "$SCOPE" != "user" && "$SCOPE" != "project" ]]; then
        echo "Error: scope must be 'user' or 'project', got '${SCOPE}'" >&2
        usage
      fi
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Error: unknown option '$1'" >&2
      usage
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve target directory
# ---------------------------------------------------------------------------
if [[ "$SCOPE" == "user" ]]; then
  TARGET_DIR="${HOME}/.claude/commands"
else
  TARGET_DIR=".claude/commands"
fi

# ---------------------------------------------------------------------------
# Resolve source directory (where this script lives)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Helper: copy a component directory
# ---------------------------------------------------------------------------
copy_components() {
  local src_dir="$1"
  local component_name="$2"
  local count=0

  if [[ ! -d "${SCRIPT_DIR}/${src_dir}" ]]; then
    echo "  [skip] ${src_dir}/ not found"
    return
  fi

  local dest_dir="${TARGET_DIR}/${src_dir}"
  mkdir -p "${dest_dir}"

  for file in "${SCRIPT_DIR}/${src_dir}"/*; do
    if [[ -f "$file" ]]; then
      cp "$file" "${dest_dir}/"
      count=$((count + 1))
    fi
  done

  echo "  [ok]   ${component_name}: ${count} file(s) -> ${dest_dir}/"
}

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
echo "ShipKit Installer"
echo "================="
echo ""
echo "Scope:  ${SCOPE}"
echo "Target: ${TARGET_DIR}"
echo ""

mkdir -p "${TARGET_DIR}"

copy_components "commands" "Commands"
copy_components "skills"   "Skills"
copy_components "agents"   "Agents"

echo ""
echo "Installation complete."
