#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# Cloud Information Module
# =============================================================================

###############################################################################
# Private Helpers
###############################################################################

###############################################################################
# Check whether AWS CLI is available.
###############################################################################
aws_available() {
    command -v aws >/dev/null 2>&1
}

###############################################################################
# Check whether Azure CLI is available.
###############################################################################
az_available() {
    command -v az >/dev/null 2>&1
}

###############################################################################
# Check whether Google Cloud CLI is available.
###############################################################################
gcloud_available() {
    command -v gcloud >/dev/null 2>&1
}

###############################################################################
# Check whether Terraform is available.
###############################################################################
terraform_available() {
    command -v terraform >/dev/null 2>&1
}

###############################################################################
# Return AWS CLI version.
###############################################################################
get_aws_version() {
    local version

    version="$(
        aws --version 2>&1 |
        sed -n 's/^aws-cli\/\([^ ]*\).*/\1/p'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Azure CLI version.
###############################################################################
get_az_version() {
    local version

    version="$(
        az version --query '"azure-cli"' -o tsv 2>/dev/null || true
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Google Cloud CLI version.
###############################################################################
get_gcloud_version() {
    local version

    version="$(
        gcloud version 2>/dev/null |
        awk '/^Google Cloud SDK / {print $4; exit}'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Terraform version.
###############################################################################
get_terraform_version() {
    local version

    version="$(
        terraform version 2>/dev/null |
        awk '/^Terraform v/ {
            sub(/^Terraform v/, "")
            print
            exit
        }'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return AWS authentication/configuration status.
#
# This intentionally does not display credentials.
###############################################################################
get_aws_auth_status() {
    local profile
    local access_key
    local secret_key
    local region

    profile="$(aws configure get profile 2>/dev/null || true)"
    access_key="$(aws configure get aws_access_key_id 2>/dev/null || true)"
    secret_key="$(aws configure get aws_secret_access_key 2>/dev/null || true)"
    region="$(aws configure get region 2>/dev/null || true)"

    if [[ -n "$access_key" && -n "$secret_key" ]]; then
        if [[ -n "$region" ]]; then
            printf "%s\n" "Configured"
        else
            printf "%s\n" "Configured (region not set)"
        fi
    elif [[ -n "$profile" || -n "$region" ]]; then
        printf "%s\n" "Partially Configured"
    else
        printf "%s\n" "Not Configured"
    fi
}

###############################################################################
# Return Azure authentication status.
#
# This uses local account information only when available.
###############################################################################
get_az_auth_status() {
    local account

    account="$(
        az account show --query id -o tsv 2>/dev/null || true
    )"

    if [[ -n "$account" ]]; then
        printf "%s\n" "Authenticated"
    else
        printf "%s\n" "Not Authenticated"
    fi
}

###############################################################################
# Return Google Cloud authentication status.
###############################################################################
get_gcloud_auth_status() {
    local account

    account="$(
        gcloud config get-value account 2>/dev/null |
        grep -v '^unset$' |
        head -n 1
    )"

    if [[ -n "$account" ]]; then
        printf "%s\n" "Authenticated"
    else
        printf "%s\n" "Not Authenticated"
    fi
}

###############################################################################
# Return Terraform working directory.
###############################################################################
get_terraform_directory() {
    if terraform_available; then
        if [[ -f "main.tf" || -f "terraform.tf" || -f "versions.tf" ]]; then
            printf "%s\n" "Terraform configuration detected"
        else
            printf "%s\n" "No configuration in current directory"
        fi
    else
        printf "%s\n" "N/A"
    fi
}

###############################################################################
# Display cloud information.
###############################################################################
cloud_info() {

    print_section "Cloud / Terraform Information"

    local aws_version="N/A"
    local aws_auth="N/A"
    local az_version="N/A"
    local az_auth="N/A"
    local gcloud_version="N/A"
    local gcloud_auth="N/A"
    local terraform_version="N/A"
    local terraform_config="N/A"

    if aws_available; then
        aws_version="$(get_aws_version)"
        aws_auth="$(get_aws_auth_status)"
        print_kv "AWS CLI Available" "Yes"
        print_kv "AWS CLI Version" "$aws_version"
        print_kv "AWS Auth Status" "$aws_auth"
    else
        print_kv "AWS CLI Available" "No"
    fi

    if az_available; then
        az_version="$(get_az_version)"
        az_auth="$(get_az_auth_status)"
        print_kv "Azure CLI Available" "Yes"
        print_kv "Azure CLI Version" "$az_version"
        print_kv "Azure Auth Status" "$az_auth"
    else
        print_kv "Azure CLI Available" "No"
    fi

    if gcloud_available; then
        gcloud_version="$(get_gcloud_version)"
        gcloud_auth="$(get_gcloud_auth_status)"
        print_kv "GCloud Available" "Yes"
        print_kv "GCloud Version" "$gcloud_version"
        print_kv "GCloud Auth Status" "$gcloud_auth"
    else
        print_kv "GCloud Available" "No"
    fi

    if terraform_available; then
        terraform_version="$(get_terraform_version)"
        terraform_config="$(get_terraform_directory)"
        print_kv "Terraform Available" "Yes"
        print_kv "Terraform Version" "$terraform_version"
        print_kv "Terraform Config" "$terraform_config"
    else
        print_kv "Terraform Available" "No"
    fi
}
