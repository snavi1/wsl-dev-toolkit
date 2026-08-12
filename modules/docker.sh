#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# Docker Information Module
# =============================================================================

###############################################################################
# Private Helpers
###############################################################################

###############################################################################
# Check whether Docker CLI is available.
#
# Returns:
#   0 - Docker CLI is available.
#   1 - Docker CLI is unavailable.
###############################################################################
docker_available() {

    command -v docker >/dev/null 2>&1
}

###############################################################################
# Check whether the Docker daemon is reachable.
#
# Returns:
#   0 - Docker daemon is reachable.
#   1 - Docker daemon is unavailable.
###############################################################################
docker_daemon_available() {

    docker info >/dev/null 2>&1
}

###############################################################################
# Return a Docker CLI value.
#
# Arguments:
#   $1 - Docker command arguments
#
# Outputs:
#   Requested value or N/A.
###############################################################################
get_docker_value() {

    local value

    value="$("$@" 2>/dev/null || true)"

    printf "%s\n" "${value:-N/A}"
}

###############################################################################
# Return the active Docker context.
###############################################################################
get_docker_context() {

    local context

    context="$(
        docker context show 2>/dev/null || true
    )"

    printf "%s\n" "${context:-N/A}"
}

###############################################################################
# Return Docker server version.
###############################################################################
get_docker_server_version() {

    local version

    version="$(
        docker version \
            --format '{{.Server.Version}}' \
            2>/dev/null || true
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Docker storage driver.
###############################################################################
get_docker_storage_driver() {

    local driver

    driver="$(
        docker info \
            --format '{{.Driver}}' \
            2>/dev/null || true
    )"

    printf "%s\n" "${driver:-N/A}"
}

###############################################################################
# Return Docker root directory.
###############################################################################
get_docker_root_dir() {

    local root_dir

    root_dir="$(
        docker info \
            --format '{{.DockerRootDir}}' \
            2>/dev/null || true
    )"

    printf "%s\n" "${root_dir:-N/A}"
}

###############################################################################
# Return container count.
###############################################################################
get_docker_container_count() {

    docker ps -a -q 2>/dev/null | wc -l
}

###############################################################################
# Return running container count.
###############################################################################
get_docker_running_count() {

    docker ps -q 2>/dev/null | wc -l
}

###############################################################################
# Return image count.
###############################################################################
get_docker_image_count() {

    docker images -q 2>/dev/null | wc -l
}

###############################################################################
# Return Docker Compose version.
###############################################################################
get_docker_compose_version() {

    local version

    version="$(
        docker compose version \
            --short \
            2>/dev/null || true
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Docker system disk usage.
###############################################################################
get_docker_disk_usage() {

    local usage

    usage="$(
        docker system df --format '{{.Size}}' 2>/dev/null |
        awk '
            {
                gsub(/B$/, "", $1)
                total += $1
            }

            END {
                printf "%.0fB\n", total
            }
        '
    )"

    printf "%s\n" "${usage:-N/A}"
}
###############################################################################
# Display Docker information.
###############################################################################
docker_info_module() {

    print_section "Docker Information"

    if ! docker_available; then
        print_kv "Docker Available" "No"
        return 0
    fi

    if ! docker_daemon_available; then
        print_kv "Docker Available" "Yes"
        print_kv "Docker Daemon" "Unavailable"
        print_kv "Docker Context" "$(get_docker_context)"
        return 0
    fi

    local client_version
    local server_version
    local context
    local compose_version
    local storage_driver
    local root_dir
    local containers
    local running
    local images
    local disk_usage
    local swarm

    client_version="$(
        docker version \
            --format '{{.Client.Version}}' \
            2>/dev/null || true
    )"

    server_version="$(get_docker_server_version)"
    context="$(get_docker_context)"
    compose_version="$(get_docker_compose_version)"
    storage_driver="$(get_docker_storage_driver)"
    root_dir="$(get_docker_root_dir)"
    containers="$(get_docker_container_count)"
    running="$(get_docker_running_count)"
    images="$(get_docker_image_count)"
    disk_usage="$(get_docker_disk_usage)"

    swarm="$(
        docker info \
            --format '{{.Swarm.LocalNodeState}}' \
            2>/dev/null || true
    )"

    printf -v client_version "%s" "${client_version:-N/A}"
    printf -v swarm "%s" "${swarm:-N/A}"

    print_kv "Docker Available" "Yes"
    print_kv "Docker Daemon" "Available"
    print_kv "Client Version" "$client_version"
    print_kv "Server Version" "$server_version"
    print_kv "Docker Context" "$context"
    print_kv "Compose Version" "$compose_version"
    print_kv "Storage Driver" "$storage_driver"
    print_kv "Docker Root Dir" "$root_dir"
    print_kv "Containers" "$containers"
    print_kv "Running Containers" "$running"
    print_kv "Images" "$images"
    print_kv "Disk Usage" "$disk_usage"
    print_kv "Swarm" "$swarm"
}
