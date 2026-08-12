#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# GPU Information Module
# =============================================================================

###############################################################################
# Private Helpers
###############################################################################

###############################################################################
# Check whether NVIDIA GPU tooling is available.
#
# Returns:
#   0 - nvidia-smi is available.
#   1 - nvidia-smi is unavailable.
###############################################################################
gpu_available() {

    command -v nvidia-smi >/dev/null 2>&1
}

###############################################################################
# Return a single GPU field using nvidia-smi.
#
# Arguments:
#   $1 - Query field
#
# Outputs:
#   Requested GPU field or N/A.
###############################################################################
get_gpu_value() {

    local field="$1"
    local value

    value="$(
        nvidia-smi \
            --query-gpu="$field" \
            --format=csv,noheader,nounits 2>/dev/null |
            head -n 1
    )"

    printf "%s\n" "${value:-N/A}"
}

###############################################################################
# Return NVIDIA-SMI version.
###############################################################################
get_nvidia_smi_version() {

    local version

    version="$(
        nvidia-smi --version 2>/dev/null |
        awk '$1 == "NVIDIA-SMI" {
            print $4
            exit
        }'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return CUDA version reported by NVIDIA-SMI.
###############################################################################
get_cuda_version() {

    local version

    version="$(
        nvidia-smi 2>/dev/null |
        awk -F'CUDA Version: ' '/CUDA Version:/ {
            print $2
            exit
        }' |
        awk '{print $1}'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return WSL GPU device status.
###############################################################################
get_wsl_gpu_status() {

    if [[ -e /dev/dxg ]]; then
        printf "Available\n"
    else
        printf "Unavailable\n"
    fi
}

###############################################################################
# Display GPU information.
###############################################################################
gpu_info() {

    print_section "GPU Information"

    if ! gpu_available; then
        print_kv "GPU Available" "No"
        print_kv "WSL GPU Device" "$(get_wsl_gpu_status)"
        return 0
    fi

    local name
    local driver
    local memory_total
    local memory_used
    local memory_free
    local utilization
    local temperature
    local power
    local nvidia_smi
    local cuda
    local wsl_gpu

    name="$(get_gpu_value "name")"
    driver="$(get_gpu_value "driver_version")"
    memory_total="$(get_gpu_value "memory.total")"
    memory_used="$(get_gpu_value "memory.used")"
    memory_free="$(get_gpu_value "memory.free")"
    utilization="$(get_gpu_value "utilization.gpu")"
    temperature="$(get_gpu_value "temperature.gpu")"
    power="$(get_gpu_value "power.draw")"
    nvidia_smi="$(get_nvidia_smi_version)"
    cuda="$(get_cuda_version)"
    wsl_gpu="$(get_wsl_gpu_status)"

    if [[ "$power" == "[N/A]" || -z "$power" ]]; then
        power="N/A"
    else
        power="${power} W"
    fi

    print_kv "GPU Available" "Yes"
    print_kv "GPU" "$name"
    print_kv "Driver Version" "$driver"
    print_kv "NVIDIA-SMI" "$nvidia_smi"
    print_kv "CUDA Version" "$cuda"
    print_kv "VRAM Total" "${memory_total} MiB"
    print_kv "VRAM Used" "${memory_used} MiB"
    print_kv "VRAM Free" "${memory_free} MiB"
    print_kv "GPU Utilization" "${utilization} %"
    print_kv "Temperature" "${temperature} °C"
    print_kv "Power Usage" "$power"
    print_kv "WSL GPU Device" "$wsl_gpu"
}
