#!/usr/bin/env bash

###############################################################################
# Memory Module
#
# Description:
#   Collects memory and swap diagnostics for Linux and WSL.
#
# Dependencies:
#   common.sh
#       - print_section()
#       - print_kv()
#
#   format.sh
#       - format_bytes()
#       - format_percentage()
###############################################################################

###############################################################################
# Private Helper Functions
###############################################################################

get_meminfo_value() {

    local data="$1"
    local field="$2"

    awk -v key="$field" '
    $1 == key ":" {
        print $2
        exit
    }' <<< "$data"
}

###############################################################################

get_free_field() {

    local data="$1"
    local row="$2"
    local column="$3"

    awk -v r="$row" -v c="$column" '
    {
        sub(/:$/, "", $1)

        if ($1 == r) {
            print $c
            exit
        }
    }' <<< "$data"
}

###############################################################################

get_swappiness() {

    local file="/proc/sys/vm/swappiness"

    if [[ -r "$file" ]]; then
        <"$file" read -r value
        printf "%s\n" "$value"
    else
        printf "N/A\n"
    fi
}

###############################################################################

get_thp_status() {

    local file="/sys/kernel/mm/transparent_hugepage/enabled"

    if [[ ! -r "$file" ]]; then
        printf "N/A\n"
        return
    fi

    awk '
    {
        for (i = 1; i <= NF; i++) {

            if ($i ~ /^\[/) {

                gsub(/\[/, "", $i)
                gsub(/\]/, "", $i)

                print $i
                exit
            }
        }
    }' "$file"
}

###############################################################################
# Public Function
###############################################################################

memory_info() {

    local free_output
    local meminfo

    local total
    local used
    local free
    local available

    local usage

    local swap_total
    local swap_used
    local swap_free

    local huge_total
    local huge_free
    local huge_size

    local swappiness
    local thp
    local numa

    print_section "Memory Information"

    ###########################################################################
    # Cache command output
    ###########################################################################

    free_output="$(free -b)"
    meminfo="$(</proc/meminfo)"

    ###########################################################################
    # Memory
    ###########################################################################

    total=$(get_free_field "$free_output" Mem 2)
    used=$(get_free_field "$free_output" Mem 3)
    free=$(get_free_field "$free_output" Mem 4)
    available=$(get_free_field "$free_output" Mem 7)

    usage=$(
        awk \
            -v u="$used" \
            -v t="$total" '
        BEGIN {
            if (t > 0)
                printf "%.1f", (u / t) * 100
            else
                printf "0.0"
        }'
    )

    print_kv "Total Memory"     "$(format_bytes "$total")"
    print_kv "Used Memory"      "$(format_bytes "$used")"
    print_kv "Free Memory"      "$(format_bytes "$free")"
    print_kv "Available Memory" "$(format_bytes "$available")"
    print_kv "Memory Usage"     "$(format_percentage "$usage")"

    echo

    ###########################################################################
    # Swap
    ###########################################################################

    swap_total=$(get_free_field "$free_output" Swap 2)
    swap_used=$(get_free_field "$free_output" Swap 3)
    swap_free=$(get_free_field "$free_output" Swap 4)

    print_kv "Swap Total" "$(format_bytes "$swap_total")"
    print_kv "Swap Used"  "$(format_bytes "$swap_used")"
    print_kv "Swap Free"  "$(format_bytes "$swap_free")"

    echo

    ###########################################################################
    # Swappiness
    ###########################################################################

    swappiness=$(get_swappiness)

    print_kv "Swappiness" "$swappiness"

    echo

    ###########################################################################
    # Huge Pages
    ###########################################################################

    huge_total=$(get_meminfo_value "$meminfo" "HugePages_Total")
    huge_free=$(get_meminfo_value "$meminfo" "HugePages_Free")
    huge_size=$(get_meminfo_value "$meminfo" "Hugepagesize")

    print_kv "Huge Pages Total" "${huge_total:-N/A}"
    print_kv "Huge Pages Free"  "${huge_free:-N/A}"

    if [[ -n "$huge_size" ]]; then
        print_kv "Huge Page Size" "${huge_size} kB"
    else
        print_kv "Huge Page Size" "N/A"
    fi

    echo

    ###########################################################################
    # Transparent Huge Pages
    ###########################################################################

    thp=$(get_thp_status)

    print_kv "Transparent HP" "$thp"

    ###########################################################################
    # NUMA
    ###########################################################################

    numa=$(
        lscpu |
        awk -F: '
        /NUMA node\(s\)/ {
            gsub(/^[[:space:]]+/, "", $2)
            print $2
            exit
        }'
    )

    print_kv "NUMA Nodes" "${numa:-N/A}"
}
