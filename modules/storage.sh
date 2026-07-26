#!/usr/bin/env bash

###############################################################################
# Storage Module
#
# Description:
#   Collects filesystem and storage diagnostics.
#
# Dependencies:
#   common.sh
#       - print_section()
#       - print_kv()
#
#   format.sh
#       - format_bytes()
###############################################################################

###############################################################################
# Private Helper Functions
###############################################################################

###############################################################################
# Returns a field from cached `df -B1 /` output.
###############################################################################
get_df_value() {

    local data="$1"
    local field="$2"

    awk -v key="$field" '
    NR == 2 {

        if (key == "filesystem")
            print $1

        else if (key == "size")
            print $2

        else if (key == "used")
            print $3

        else if (key == "available")
            print $4

        else if (key == "use")
            print $5

        else if (key == "mount")
            print $6

        exit
    }' <<< "$data"
}

###############################################################################
# Returns a field from cached `df -i /` output.
###############################################################################
get_inode_value() {

    local data="$1"
    local field="$2"

    awk -v key="$field" '
    NR == 2 {

        if (key == "used")
            print $3

        else if (key == "free")
            print $4

        else if (key == "use")
            print $5

        exit
    }' <<< "$data"
}

###############################################################################
# Returns information from findmnt.
###############################################################################
get_mount_value() {

    local option="$1"

    findmnt -no "$option" / 2>/dev/null || printf "N/A\n"
}

###############################################################################
# Returns the active I/O scheduler.
###############################################################################
get_scheduler() {

    local device="$1"
    local file="/sys/block/${device}/queue/scheduler"

    [[ -r "$file" ]] || {
        printf "N/A\n"
        return
    }

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
# Returns TRIM support.
###############################################################################
get_trim_support() {

    local device="$1"
    local file="/sys/block/${device}/queue/discard_max_bytes"

    [[ -r "$file" ]] || {
        printf "N/A\n"
        return
    }

    local value
    value=$(<"$file")

    if [[ "$value" -gt 0 ]]; then
        printf "Supported\n"
    else
        printf "Not Supported\n"
    fi
}

###############################################################################
# Detect WSL.
###############################################################################
if is_wsl; then
    print_kv "WSL Environment" "Yes"
else
    print_kv "WSL Environment" "No"
fi
###############################################################################
# Public Function
###############################################################################

storage_info() {

    local df_output
    local inode_output

    local filesystem
    local device
    local mount_point

    local total
    local used
    local available
    local usage

    local inode_used
    local inode_free
    local inode_usage

    local block_device
    local scheduler
    local trim

    print_section "Storage Information"

    ###########################################################################
    # Cache command output
    ###########################################################################

    df_output="$(df -B1 /)"
    inode_output="$(df -i /)"

    ###########################################################################
    # Filesystem information
    ###########################################################################

    filesystem=$(get_mount_value FSTYPE)
    device=$(get_mount_value SOURCE)
    mount_point=$(get_mount_value TARGET)

    total=$(get_df_value "$df_output" size)
    used=$(get_df_value "$df_output" used)
    available=$(get_df_value "$df_output" available)
    usage=$(get_df_value "$df_output" use)

    print_kv "Filesystem"      "$filesystem"
    print_kv "Root Device"     "$device"
    print_kv "Mount Point"     "$mount_point"

    echo

    print_kv "Total Size"      "$(format_bytes "$total")"
    print_kv "Used Space"      "$(format_bytes "$used")"
    print_kv "Available Space" "$(format_bytes "$available")"
    print_kv "Disk Usage"      "$(format_percentage "${usage%\%}")"

    echo

    ###########################################################################
    # Inodes
    ###########################################################################

    inode_used=$(get_inode_value "$inode_output" used)
    inode_free=$(get_inode_value "$inode_output" free)
    inode_usage=$(get_inode_value "$inode_output" use)

    inode_usage="${inode_usage%\%}"

    print_kv "Inodes Used" "${inode_used:-N/A}"
    print_kv "Inodes Free" "${inode_free:-N/A}"
    print_kv "Inode Usage" "$(format_percentage "$inode_usage")"

    echo
    ###########################################################################
    # Scheduler / TRIM
    ###########################################################################

    block_device="${device##*/}"

    scheduler=$(get_scheduler "$block_device")
    trim=$(get_trim_support "$block_device")

    print_kv "Disk Scheduler" "$scheduler"
    print_kv "TRIM Support"   "$trim"

    echo

    ###########################################################################
    # Environment
    ###########################################################################

    if is_wsl; then
        print_kv "WSL Environment" "Yes"
    else
        print_kv "WSL Environment" "No"
    fi
}
