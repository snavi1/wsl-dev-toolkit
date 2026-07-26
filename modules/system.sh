#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# System Information Module
# =============================================================================

system_info() {

    local os
    local kernel
    local arch
    local hostname
    local user
    local shell
    local uptime

    os="$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    kernel="$(uname -r)"
    arch="$(uname -m)"
    hostname="$(hostname)"
    user="$(whoami)"
    shell="${SHELL##*/}"
    uptime="$(uptime -p)"

    print_section "System Information"

    print_kv "Operating System" "$os"
    print_kv "Kernel" "$kernel"
    print_kv "Architecture" "$arch"
    print_kv "Hostname" "$hostname"
    print_kv "User" "$user"
    print_kv "Shell" "$shell"
    print_kv "Uptime" "$uptime"
}
