#!/usr/bin/env bash

###############################################################################
# Platform Detection Library
#
# Shared platform and environment detection helpers.
###############################################################################

is_wsl() {
    [[ -n "${WSL_DISTRO_NAME:-}" ]] && return 0
    [[ -r /proc/sys/fs/binfmt_misc/WSLInterop ]] && return 0
    grep -qi microsoft /proc/version 2>/dev/null
}

is_docker() {
    [[ -f /.dockerenv ]] && return 0
    grep -q docker /proc/1/cgroup 2>/dev/null
}

is_systemd() {
    [[ -d /run/systemd/system ]]
}

platform_name() {

    if is_wsl; then
        printf "WSL2\n"
    elif is_docker; then
        printf "Docker\n"
    else
        printf "Linux\n"
    fi
}
