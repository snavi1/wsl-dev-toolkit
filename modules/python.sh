#!/usr/bin/env bash
#
# =============================================================================
# WSL Developer Toolkit
# Python / Conda Information Module
# =============================================================================

###############################################################################
# Private Helpers
###############################################################################

###############################################################################
# Check whether Python 3 is available.
###############################################################################
python_available() {

    command -v python3 >/dev/null 2>&1
}

###############################################################################
# Check whether Conda is available.
###############################################################################
conda_available() {

    command -v conda >/dev/null 2>&1
}

###############################################################################
# Return Python version.
###############################################################################
get_python_version() {

    local version

    version="$(
        python3 --version 2>/dev/null |
        awk '{print $2}'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Python executable.
###############################################################################
get_python_executable() {

    local executable

    executable="$(
        python3 -c 'import sys; print(sys.executable)' 2>/dev/null || true
    )"

    printf "%s\n" "${executable:-N/A}"
}

###############################################################################
# Return Python prefix.
###############################################################################
get_python_prefix() {

    local prefix

    prefix="$(
        python3 -c 'import sys; print(sys.prefix)' 2>/dev/null || true
    )"

    printf "%s\n" "${prefix:-N/A}"
}

###############################################################################
# Return pip version.
###############################################################################
get_pip_version() {

    local version

    version="$(
        python3 -m pip --version 2>/dev/null |
        awk '{print $2}'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Conda version.
###############################################################################
get_conda_version() {

    local version

    version="$(
        conda --version 2>/dev/null |
        awk '{print $2}'
    )"

    printf "%s\n" "${version:-N/A}"
}

###############################################################################
# Return Conda executable.
###############################################################################
get_conda_executable() {

    local executable

    executable="$(
        command -v conda 2>/dev/null || true
    )"

    printf "%s\n" "${executable:-N/A}"
}

###############################################################################
# Return active Conda environment.
###############################################################################
get_conda_environment() {

    printf "%s\n" "${CONDA_DEFAULT_ENV:-None}"
}

###############################################################################
# Return number of Conda environments.
###############################################################################
###############################################################################
# Return Conda environment names.
###############################################################################
get_conda_environment_list() {

    local environments

    environments="$(
        conda env list 2>/dev/null |
        awk '
            /^[[:space:]]*#/ { next }
            /^[[:space:]]*$/ { next }
            {
                name=$1
                sub(/^\*/, "", name)
                names[++count]=name
            }
            END {
                for (i = 1; i <= count; i++) {
                    printf "%s%s", names[i], (i < count ? ", " : "")
                }
            }
        '
    )"

    printf "%s\n" "${environments:-None}"
}
###############################################################################
# Display Python / Conda information.
###############################################################################
python_info() {

    print_section "Python / Conda Information"

    if python_available; then

        local python_version
        local python_executable
        local python_prefix
        local pip_version

        python_version="$(get_python_version)"
        python_executable="$(get_python_executable)"
        python_prefix="$(get_python_prefix)"
        pip_version="$(get_pip_version)"

        print_kv "Python Available" "Yes"
        print_kv "Python Version" "$python_version"
        print_kv "Python Executable" "$python_executable"
        print_kv "Python Prefix" "$python_prefix"
        print_kv "pip Version" "$pip_version"

    else

        print_kv "Python Available" "No"
    fi

    if conda_available; then

        local conda_version
        local conda_executable
        local conda_environment
        local conda_environment_count
	local conda_environment_list

        conda_version="$(get_conda_version)"
        conda_executable="$(get_conda_executable)"
        conda_environment="$(get_conda_environment)"
        conda_environment_count="$(get_conda_environment_count)"
	conda_environment_list="$(get_conda_environment_list)"

        print_kv "Conda Available" "Yes"
        print_kv "Conda Version" "$conda_version"
        print_kv "Conda Executable" "$conda_executable"
        print_kv "Active Environment" "$conda_environment"
        print_kv "Environments" "$conda_environment_count"
	print_kv "Environment List" "$conda_environment_list"

    else

        print_kv "Conda Available" "No"
    fi
}
