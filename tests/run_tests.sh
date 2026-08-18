#!/usr/bin/env bash

###############################################################################
# WSL Developer Toolkit
# Test Runner
###############################################################################

set -o errexit
set -o nounset
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PASS_COUNT=0
FAIL_COUNT=0

###############################################################################
# Test helpers
###############################################################################

pass() {
    printf "[ PASS ] %s\n" "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    printf "[ FAIL ] %s\n" "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

###############################################################################
# Run a command and verify success.
###############################################################################

test_command() {
    local description="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        pass "$description"
    else
        fail "$description"
    fi
}

###############################################################################
# Main
###############################################################################

main() {

    echo
    echo "========================================="
    echo "      WSL Developer Toolkit Tests"
    echo "========================================="
    echo

    echo "CLI Tests"
    echo "-----------------------------------------"

    test_command "wdt help" \
        "$PROJECT_ROOT/bin/wdt" help

    test_command "wdt --help" \
        "$PROJECT_ROOT/bin/wdt" --help

    test_command "wdt version" \
        "$PROJECT_ROOT/bin/wdt" version

    echo
    echo "Syntax Tests"
    echo "-----------------------------------------"

    while IFS= read -r -d '' script; do
        if bash -n "$script" >/dev/null 2>&1; then
            pass "bash -n $(basename "$script")"
        else
            fail "bash -n $(basename "$script")"
        fi
    done < <(
        find "$PROJECT_ROOT/bin" \
             "$PROJECT_ROOT/lib" \
             "$PROJECT_ROOT/modules" \
             "$PROJECT_ROOT/scripts" \
             -type f \
             -name "*.sh" \
             -print0
    )

    echo
    echo "Lint Tests"
    echo "-----------------------------------------"

    if "$PROJECT_ROOT/scripts/lint.sh" >/dev/null 2>&1; then
        pass "ShellCheck project"
    else
        fail "ShellCheck project"
    fi

    echo
    echo "Integration Tests"
    echo "-----------------------------------------"

    if "$PROJECT_ROOT/bin/wdt" doctor >/dev/null 2>&1; then
        pass "wdt doctor"
    else
        fail "wdt doctor"
    fi

    echo
    echo "========================================="
    printf "Passed : %d\n" "$PASS_COUNT"
    printf "Failed : %d\n" "$FAIL_COUNT"
    echo "========================================="
    echo

    if (( FAIL_COUNT > 0 )); then
        return 1
    fi

    return 0
}

main "$@"
