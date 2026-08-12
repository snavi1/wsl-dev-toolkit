#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# Network Information Module
# =============================================================================

###############################################################################
# Private Helpers
###############################################################################

###############################################################################
# Check required networking commands.
#
# Returns:
#   0 - All required commands are available.
#   1 - One or more commands are missing.
###############################################################################
require_network_tools() {

    require_command ip &&
    require_command awk
}

###############################################################################
# Convert CIDR prefix length to dotted-decimal subnet mask.
#
# Arguments:
#   $1 - CIDR prefix (0-32)
#
# Outputs:
#   Prints subnet mask.
#
# Returns:
#   0 - Success.
#   1 - Invalid CIDR.
###############################################################################
cidr_to_netmask() {

    local cidr="$1"
    local mask=()
    local i

    [[ "$cidr" =~ ^[0-9]+$ ]] || return 1
    (( cidr >= 0 && cidr <= 32 )) || return 1

    for (( i = 0; i < 4; i++ )); do
        if (( cidr >= 8 )); then
            mask+=(255)
            (( cidr -= 8 ))
        elif (( cidr > 0 )); then
            mask+=("$((256 - 2 ** (8 - cidr)))")
            cidr=0
        else
            mask+=(0)
        fi
    done

    printf '%s.%s.%s.%s\n' \
        "${mask[0]}" \
        "${mask[1]}" \
        "${mask[2]}" \
        "${mask[3]}"
}

###############################################################################
# Get link speed using ethtool.
#
# Arguments:
#   $1 - Interface name
#
# Outputs:
#   Prints link speed when available.
###############################################################################
get_link_speed() {

    local interface="$1"

    if ! require_command ethtool; then
        printf 'Unavailable\n'
        return 0
    fi

    ethtool "$interface" 2>/dev/null |
        awk -F': ' '$1 == "Speed" { print $2; exit }'
}

###############################################################################
# Get network driver using ethtool.
#
# Arguments:
#   $1 - Interface name
#
# Outputs:
#   Prints driver name when available.
###############################################################################
get_driver_info() {

    local interface="$1"

    if ! require_command ethtool; then
        printf 'Unavailable\n'
        return 0
    fi

    ethtool -i "$interface" 2>/dev/null |
        awk -F': ' '$1 == "driver" { print $2; exit }'
}

###############################################################################
# Get network bus information using lshw.
#
# Arguments:
#   $1 - Interface name
#
# Outputs:
#   Prints bus information when available.
###############################################################################
get_bus_info() {

    local interface="$1"

    if ! require_command lshw; then
        printf 'Unavailable\n'
        return 0
    fi

    lshw -C network -businfo 2>/dev/null |
        awk -v iface="$interface" '
            $0 ~ iface {
                print $1
                exit
            }
        '
}

###############################################################################
# Detect whether the current environment is WSL.
#
# Outputs:
#   Yes
#   No
###############################################################################
get_wsl_status() {

    if grep -qi microsoft /proc/version 2>/dev/null; then
        printf 'Yes\n'
    else
        printf 'No\n'
    fi
}

###############################################################################
# Parsers
###############################################################################

###############################################################################
# Parse default route information.
#
# Arguments:
#   $1 - Cached output of `ip route`
#
# Outputs:
#   default=yes|no
#   gateway=<address>
#   interface=<name>
#
# Returns:
#   0 - Parser completed.
###############################################################################
parse_route() {

    local route_cache="$1"

    awk '
        /^default[[:space:]]/ {
            default_route = "yes"

            for (i = 1; i <= NF; i++) {
                if ($i == "via" && (i + 1) <= NF) {
                    gateway = $(i + 1)
                }

                if ($i == "dev" && (i + 1) <= NF) {
                    interface = $(i + 1)
                }
            }

            print "default=" default_route

            if (gateway != "") {
                print "gateway=" gateway
            }

            if (interface != "") {
                print "interface=" interface
            }

            found = 1
            exit
        }

        END {
            if (!found) {
                print "default=no"
            }
        }
    ' <<<"$route_cache"
}

###############################################################################
# Parse DNS configuration.
#
# Arguments:
#   $1 - Cached contents of /etc/resolv.conf
#
# Outputs:
#   servers=<comma-separated DNS servers>
#   search=<comma-separated search domains>
#
# Returns:
#   0 - Parser completed.
###############################################################################
parse_dns() {

    local resolv_cache="$1"

    awk '
        $1 == "nameserver" && $2 != "" {
            if (servers != "") {
                servers = servers ", "
            }

            servers = servers $2
        }

        $1 == "search" {
            for (i = 2; i <= NF; i++) {
                if (search != "") {
                    search = search ", "
                }

                search = search $i
            }
        }

        $1 == "domain" && $2 != "" && search == "" {
            search = $2
        }

        END {
            if (servers != "") {
                print "servers=" servers
            } else {
                print "servers=Unavailable"
            }

            if (search != "") {
                print "search=" search
            } else {
                print "search=Unavailable"
            }
        }
    ' <<<"$resolv_cache"
}

###############################################################################
# Parse interface information.
#
# Arguments:
#   $1 - Cached output of `ip addr`
#   $2 - Interface name
#
# Outputs:
#   state=<UP|DOWN>
#   mtu=<value>
#   mac=<address>
#   ipv4=<address>
#   cidr=<prefix>
#   broadcast=<address>
#   ipv6=<address>
#
# Returns:
#   0 - Interface found.
#   1 - Interface not found.
###############################################################################
parse_interface() {

    local addr_cache="$1"
    local interface="$2"

    awk -v target="$interface" '
        BEGIN {
            found = 0
            state = ""
            mtu = ""
            mac = ""
            ipv4 = ""
            cidr = ""
            broadcast = ""
            ipv6 = ""
        }

        #
        # Interface header.
        #
        /^[0-9]+:/ {
            name = $2
            sub(/:$/, "", name)
            sub(/@.*/, "", name)

            if (found && name != target) {
                exit
            }

            if (name == target) {
                found = 1

                if ($0 ~ /<[^>]*UP[^>]*>/) {
                    state = "UP"
                } else {
                    state = "DOWN"
                }

                for (i = 1; i <= NF; i++) {
                    if ($i == "mtu" && (i + 1) <= NF) {
                        mtu = $(i + 1)
                    }
                }
            }

            next
        }

        #
        # Ignore everything until target interface is found.
        #
        !found {
            next
        }

        #
        # MAC address.
        #
        /^[[:space:]]+link\/ether[[:space:]]/ {
            mac = $2
            next
        }

        #
        # IPv4 address.
        #
        /^[[:space:]]+inet[[:space:]]/ {
            split($2, address, "/")

            if (ipv4 == "") {
                ipv4 = address[1]
                cidr = address[2]
            }

            for (i = 1; i <= NF; i++) {
                if ($i == "brd" && (i + 1) <= NF) {
                    broadcast = $(i + 1)
                }
            }

            next
        }

        #
        # IPv6 address.
        #
        /^[[:space:]]+inet6[[:space:]]/ {
            split($2, address, "/")

            if (ipv6 == "" && address[1] !~ /^fe80:/) {
                ipv6 = address[1]
            }

            if (ipv6 == "" && address[1] ~ /^fe80:/) {
                ipv6 = address[1]
            }

            next
        }

        END {
            if (!found) {
                exit 1
            }

            if (state != "") {
                print "state=" state
            }

            if (mtu != "") {
                print "mtu=" mtu
            }

            if (mac != "") {
                print "mac=" mac
            }

            if (ipv4 != "") {
                print "ipv4=" ipv4
            }

            if (cidr != "") {
                print "cidr=" cidr
            }

            if (broadcast != "") {
                print "broadcast=" broadcast
            }

            if (ipv6 != "") {
                print "ipv6=" ipv6
            }
        }
    ' <<<"$addr_cache"
}

###############################################################################
# Public API
###############################################################################

###############################################################################
# Display network information.
#
# Returns:
#   0 - Network information displayed successfully.
#   1 - Required networking tools unavailable.
###############################################################################
network_info() {

    require_network_tools || {
        log_warn "Required networking commands are unavailable."
        return 1
    }

    local route_cache
    local addr_cache
    local resolv_cache

    route_cache="$(ip route 2>/dev/null)"
    addr_cache="$(ip addr 2>/dev/null)"
    resolv_cache="$(cat /etc/resolv.conf 2>/dev/null || true)"

    local hostname
    hostname="$(hostname 2>/dev/null || printf 'Unavailable')"

    local default_route="no"
    local gateway="Unavailable"
    local interface="Unavailable"

    while IFS='=' read -r key value; do
        case "$key" in
            default)
                default_route="$value"
                ;;
            gateway)
                gateway="$value"
                ;;
            interface)
                interface="$value"
                ;;
        esac
    done < <(parse_route "$route_cache")

    local state="Unavailable"
    local mtu="Unavailable"
    local mac="Unavailable"
    local ipv4="Unavailable"
    local cidr="Unavailable"
    local broadcast="Unavailable"
    local ipv6="Unavailable"
    local netmask="Unavailable"

    if [[ "$interface" != "Unavailable" ]]; then

        while IFS='=' read -r key value; do
            case "$key" in
                state)
                    state="$value"
                    ;;
                mtu)
                    mtu="$value"
                    ;;
                mac)
                    mac="$value"
                    ;;
                ipv4)
                    ipv4="$value"
                    ;;
                cidr)
                    cidr="$value"
                    ;;
                broadcast)
                    broadcast="$value"
                    ;;
                ipv6)
                    ipv6="$value"
                    ;;
            esac
        done < <(parse_interface "$addr_cache" "$interface")

        if [[ "$cidr" != "Unavailable" ]]; then
            netmask="$(cidr_to_netmask "$cidr" 2>/dev/null || printf 'Unavailable')"
            cidr="/$cidr"
        fi
    fi

    local dns_servers="Unavailable"
    local search_domains="Unavailable"

    while IFS='=' read -r key value; do
        case "$key" in
            servers)
                dns_servers="$value"
                ;;
            search)
                search_domains="$value"
                ;;
        esac
    done < <(parse_dns "$resolv_cache")

    local speed="Unavailable"
    local driver="Unavailable"
    local wsl_status

    if [[ "$interface" != "Unavailable" ]]; then
        speed="$(get_link_speed "$interface")"
        driver="$(get_driver_info "$interface")"

        [[ -n "$speed" ]] || speed="Unavailable"
        [[ -n "$driver" ]] || driver="Unavailable"
    fi

    wsl_status="$(get_wsl_status)"

    print_section "Network Information"

    print_kv "Hostname" "$hostname"
    print_kv "Primary Interface" "$interface"
    print_kv "Interface State" "$state"

    print_kv "MAC Address" "$mac"
    print_kv "MTU" "$mtu"

    print_kv "IPv4 Address" "$ipv4"
    print_kv "Subnet Mask" "$netmask"
    print_kv "CIDR Prefix" "$cidr"
    print_kv "Broadcast" "$broadcast"

    print_kv "IPv6 Address" "$ipv6"

    print_kv "Gateway" "$gateway"
    print_kv "Default Route" "$default_route"

    print_kv "DNS Servers" "$dns_servers"
    print_kv "Search Domains" "$search_domains"

    print_kv "Link Speed" "$speed"
    print_kv "Driver" "$driver"

    print_kv "WSL Environment" "$wsl_status"
}
