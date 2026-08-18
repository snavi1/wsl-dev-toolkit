# WSL Developer Toolkit

A modular Bash-based diagnostic toolkit for inspecting and validating a WSL2 development workstation.

## Current Version

`0.5.0-dev`

## Overview

WSL Developer Toolkit provides a single command-line interface for collecting diagnostic information about a WSL development environment.

The toolkit currently provides diagnostics for:

- System information
- CPU
- Memory
- Storage
- Network
- NVIDIA GPU
- Docker
- Python / Conda
- Kubernetes
- Cloud CLI tools and Terraform

The primary command is:

```bash
./bin/wdt doctor
```

## Requirements

The toolkit is designed for a Linux/WSL environment with Bash.

Optional tools are detected when available:

- Git
- ShellCheck
- Python 3
- Docker
- curl
- wget
- NVIDIA `nvidia-smi`
- Conda
- `kubectl`
- AWS CLI
- Azure CLI
- Google Cloud CLI
- Terraform

The toolkit reports availability and diagnostic information rather than requiring every tool to be installed.

## Usage

From the project root:

```bash
./bin/wdt doctor
./bin/wdt version
./bin/wdt help
```

Run the complete diagnostic suite:

```bash
./bin/wdt doctor
```

Display the toolkit version:

```bash
./bin/wdt version
```

Display available commands:

```bash
./bin/wdt help
```

Run project tests:

```bash
./tests/run_tests.sh
```

Run ShellCheck:

```bash
./scripts/lint.sh
```

## Project Structure

```text
bin/        Command-line interface
lib/        Shared Bash libraries
modules/    Diagnostic modules
scripts/    Doctor and lint scripts
tests/      Project test runner
config/     Configuration files
docs/       Project documentation
templates/ Module templates
```

## Diagnostics

The `doctor` command reports the current state of the development workstation across the following areas:

- System and operating system information
- CPU and memory resources
- Storage and filesystem information
- Network configuration
- NVIDIA GPU and CUDA availability
- Docker engine and Compose
- Python, pip, and Conda environments
- Kubernetes client and cluster connectivity
- AWS, Azure, and Google Cloud CLI status
- Terraform installation and configuration

The diagnostic output is informational. A missing optional tool or unavailable service is reported rather than treated as a project failure.
