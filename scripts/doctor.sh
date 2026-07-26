#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# Doctor Command
# =============================================================================

set -o errexit
set -o nounset
set -o pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

###############################################################################
# Modules
###############################################################################

# shellcheck disable=SC1091
source "$PROJECT_ROOT/lib/common.sh"

# shellcheck disable=SC1091
source "$PROJECT_ROOT/lib/format.sh"

# shellcheck disable=SC1091
source "$PROJECT_ROOT/modules/system.sh"

# shellcheck disable=SC1091
source "$PROJECT_ROOT/modules/cpu.sh"

# shellcheck disable=SC1091
source "$PROJECT_ROOT/modules/memory.sh"

main() {

    print_header "WSL Developer Toolkit Doctor"

    system_info
    cpu_info
    memory_info

    echo

    check_command "Git" git
    check_command "ShellCheck" shellcheck
    check_command "Python3" python3
    check_command "Docker" docker
    check_command "curl" curl
    check_command "wget" wget

    echo
    log_info "Doctor check completed."
}

main "$@"
