#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# Lint Script
# =============================================================================

set -o errexit
set -o nounset
set -o pipefail

#PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo
echo "Running ShellCheck..."
echo

find "$PROJECT_ROOT" \
    -path "$PROJECT_ROOT/.git" -prune -o \
    -type f \
    -name "*.sh" \
    -print0 |
xargs -0 shellcheck -x -P "$PROJECT_ROOT"

echo
echo "========================================="
echo "✓ All project shell scripts passed."
echo "========================================="
echo
