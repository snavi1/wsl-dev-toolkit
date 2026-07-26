#!/usr/bin/env bash

###############################################################################
# Formatting Helpers
# Description : Common formatting functions used across modules
###############################################################################

###############################################################################
# Convert bytes to human-readable IEC units (KiB, MiB, GiB, TiB)
###############################################################################
format_bytes() {

    local bytes="$1"

    if [[ ! "$bytes" =~ ^[0-9]+$ ]]; then
        printf "N/A\n"
        return
    fi

    awk -v b="$bytes" '
    BEGIN {
        split("B KiB MiB GiB TiB PiB", unit)

        i = 1
        while (b >= 1024 && i < 6) {
            b /= 1024
            i++
        }

        printf "%.2f %s\n", b, unit[i]
    }'
}

###############################################################################
# Format percentage with one decimal place
###############################################################################
format_percentage() {

    local value="$1"

    if [[ -z "$value" ]]; then
        printf "N/A\n"
        return
    fi

    printf "%.1f %%\n" "$value"
}

###############################################################################
# Format CPU frequency
###############################################################################
format_frequency() {

    local mhz="$1"

    if [[ -z "$mhz" || "$mhz" == "N/A" ]]; then
        printf "N/A\n"
        return
    fi

    printf "%.2f MHz\n" "$mhz"
}

###############################################################################
# Convert seconds to a readable duration
###############################################################################
format_duration() {

    local seconds="$1"

    if [[ ! "$seconds" =~ ^[0-9]+$ ]]; then
        printf "N/A\n"
        return
    fi

    local days hours minutes secs

    days=$((seconds / 86400))
    hours=$(((seconds % 86400) / 3600))
    minutes=$(((seconds % 3600) / 60))
    secs=$((seconds % 60))

    if (( days > 0 )); then
        printf "%dd %02dh %02dm %02ds\n" \
            "$days" "$hours" "$minutes" "$secs"
    else
        printf "%02dh %02dm %02ds\n" \
            "$hours" "$minutes" "$secs"
    fi
}
