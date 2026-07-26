#!/usr/bin/env bash

###############################################################################
# CPU Module
# Description : Collect CPU information
###############################################################################

###############################################################################
# Return a field from lscpu output.
###############################################################################
get_lscpu_value() {

    local data="$1"
    local key="$2"
    local value

    value=$(
        awk -F: -v key="$key" '
            $1 == key {
                gsub(/^[[:space:]]+/, "", $2)
                print $2
                exit
            }
        ' <<< "$data"
    )

    printf "%s\n" "${value:-N/A}"
}

###############################################################################
# Return current CPU frequency.
###############################################################################
get_current_cpu_frequency() {

    local freq

    # Try lscpu first
    freq=$(get_lscpu_value "$1" "CPU MHz")

    if [[ "$freq" != "N/A" ]]; then
        printf "%s MHz\n" "$freq"
        return
    fi

    # Try /proc/cpuinfo
    if [[ -r /proc/cpuinfo ]]; then

        freq=$(
            awk -F: '/cpu MHz/ {
                gsub(/^[[:space:]]+/, "", $2)
                print $2
                exit
            }' /proc/cpuinfo
        )

        if [[ -n "$freq" ]]; then
            printf "%.2f MHz\n" "$freq"
            return
        fi
    fi

    printf "N/A\n"
}

###############################################################################
# Return maximum CPU frequency.
###############################################################################
get_max_cpu_frequency() {

    local max

    if [[ -r /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]]; then

        max=$(< /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)

        printf "%.2f MHz\n" "$(awk "BEGIN{print $max/1000}")"
        return
    fi

    max=$(get_lscpu_value "$1" "CPU max MHz")

    if [[ "$max" != "N/A" ]]; then
        printf "%s MHz\n" "$max"
        return
    fi

    printf "N/A\n"
}

###############################################################################
# Display CPU information.
###############################################################################
cpu_info() {

    local cpuinfo

    cpuinfo="$(lscpu)"

    local model
    local vendor
    local arch
    local logical
    local physical
    local threads
    local sockets
    local numa
    local current_freq
    local max_freq
    local virtualization
    local hypervisor
    local cache

    model=$(get_lscpu_value "$cpuinfo" "Model name")
    vendor=$(get_lscpu_value "$cpuinfo" "Vendor ID")
    arch=$(get_lscpu_value "$cpuinfo" "Architecture")
    logical=$(get_lscpu_value "$cpuinfo" "CPU(s)")
    physical=$(get_lscpu_value "$cpuinfo" "Core(s) per socket")
    threads=$(get_lscpu_value "$cpuinfo" "Thread(s) per core")
    sockets=$(get_lscpu_value "$cpuinfo" "Socket(s)")
    numa=$(get_lscpu_value "$cpuinfo" "NUMA node(s)")
    current_freq=$(get_current_cpu_frequency "$cpuinfo")
    max_freq=$(get_max_cpu_frequency "$cpuinfo")
    virtualization=$(get_lscpu_value "$cpuinfo" "Virtualization")
    hypervisor=$(get_lscpu_value "$cpuinfo" "Hypervisor vendor")
    cache=$(get_lscpu_value "$cpuinfo" "L3 cache")

    print_section "CPU Information"

    print_kv "Model" "$model"
    print_kv "Vendor" "$vendor"
    print_kv "Architecture" "$arch"
    print_kv "Logical CPUs" "$logical"
    print_kv "Physical Cores" "$physical"
    print_kv "Threads/Core" "$threads"
    print_kv "Sockets" "$sockets"
    print_kv "NUMA Nodes" "$numa"
    print_kv "Current Frequency" "$current_freq"
    print_kv "Max Frequency" "$max_freq"
    print_kv "Virtualization" "$virtualization"
    print_kv "Hypervisor" "$hypervisor"
    print_kv "L3 Cache" "$cache"
}
