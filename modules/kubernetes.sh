#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# Kubernetes Information Module
# =============================================================================

###############################################################################
# Private Helpers
###############################################################################

###############################################################################
# Check whether kubectl is available.
###############################################################################
kubectl_available() {

    command -v kubectl >/dev/null 2>&1
}

###############################################################################
# Return kubectl client version.
###############################################################################
get_kubectl_client_version() {

    local version

    version="$(
        kubectl version --client 2>/dev/null |
        awk -F': ' '/Client Version:/ {
            print $2
            exit
        }'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return current Kubernetes context.
###############################################################################
get_kubernetes_context() {

    local context

    context="$(
        kubectl config current-context 2>/dev/null || true
    )"

    printf "%s\n" "${context:-None}"
}

###############################################################################
# Check whether Kubernetes API server is reachable.
###############################################################################
kubernetes_cluster_available() {

    kubectl cluster-info >/dev/null 2>&1
}

###############################################################################
# Return Kubernetes server version.
###############################################################################
get_kubernetes_server_version() {

    local version

    version="$(
        kubectl version 2>/dev/null |
        awk -F': ' '/Server Version:/ {
            print $2
            exit
        }'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Kubernetes node count.
###############################################################################
get_kubernetes_node_count() {

    kubectl get nodes \
        --no-headers \
        2>/dev/null |
        wc -l
}

###############################################################################
# Display Kubernetes information.
###############################################################################
kubernetes_info() {

    print_section "Kubernetes Information"

    if ! kubectl_available; then
        print_kv "kubectl Available" "No"
        print_kv "Cluster Available" "No"
        return 0
    fi

    local client_version
    local context

    client_version="$(get_kubectl_client_version)"
    context="$(get_kubernetes_context)"

    print_kv "kubectl Available" "Yes"
    print_kv "kubectl Version" "$client_version"
    print_kv "Current Context" "$context"

    if ! kubernetes_cluster_available; then
        print_kv "Cluster Available" "No"
        print_kv "Server Version" "N/A"
        print_kv "Nodes" "N/A"
        return 0
    fi

    local server_version
    local nodes

    server_version="$(get_kubernetes_server_version)"
    nodes="$(get_kubernetes_node_count)"

    print_kv "Cluster Available" "Yes"
    print_kv "Server Version" "$server_version"
    print_kv "Nodes" "$nodes"
}
