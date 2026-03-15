#!/usr/bin/env bash
set -euo pipefail

# ShipKit Installer
# Installs ShipKit components as a Claude Code plugin.
#
# Usage:
#   ./install.sh [--scope user|project|<path>]
#
# Scope:
#   user    -> installs to ~/.claude/commands/
#   project -> installs to .claude/commands/ (default)
#   <path>  -> installs to <path>/.claude/commands/

SCOPE="project"

usage() {
  echo "Usage: $0 [--scope user|project|<path>]"
  echo ""
  echo "Options:"
  echo "  --scope user     Install to ~/.claude/commands/ (user-wide)"
  echo "  --scope project  Install to .claude/commands/  (default)"
  echo "  --scope <path>   Install to <path>/.claude/commands/"
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
elif [[ "$SCOPE" == "project" ]]; then
  TARGET_DIR=".claude/commands"
else
  # Custom path — resolve to absolute and append .claude/commands
  if [[ ! -d "$SCOPE" ]]; then
    echo "Error: directory '${SCOPE}' does not exist" >&2
    exit 1
  fi
  TARGET_DIR="$(cd "$SCOPE" && pwd)/.claude/commands"
fi

# ---------------------------------------------------------------------------
# Resolve source directory (where this script lives)
# ---------------------------------------------------------------------------
REPO_URL="https://github.com/sanmak/ship-kit"
CLEANUP_TEMP=""

if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  # Running via curl | bash — clone the repo to a temp directory
  TMPDIR_INSTALL="$(mktemp -d)"
  CLEANUP_TEMP="$TMPDIR_INSTALL"
  echo "Downloading ShipKit from ${REPO_URL}..."
  git clone --depth 1 --quiet "$REPO_URL" "$TMPDIR_INSTALL"
  SCRIPT_DIR="$TMPDIR_INSTALL"
fi

cleanup() {
  if [[ -n "$CLEANUP_TEMP" && -d "$CLEANUP_TEMP" ]]; then
    rm -rf "$CLEANUP_TEMP"
  fi
}
trap cleanup EXIT

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
