## 2026-07-26

### Completed

- Added modular CLI architecture.
- Added `lint` command to `wdt`.
- Created `modules/system.sh`.
- Refactored `doctor.sh` to use modules.
- Added reusable formatting functions:
  - `print_header`
  - `print_section`
  - `print_kv`
- Improved output formatting.
- All ShellCheck checks passing.

## 2026-08-22

### Completed

- Added CPU diagnostics.
- Added memory diagnostics.
- Added storage diagnostics.
- Added network diagnostics.
- Added NVIDIA GPU and CUDA diagnostics.
- Added Docker diagnostics.
- Added Python and Conda diagnostics.
- Added Kubernetes diagnostics.
- Added AWS, Azure, and Google Cloud CLI diagnostics.
- Added Terraform diagnostics.
- Added automated project tests.
- Added project-wide ShellCheck validation.
- Expanded README documentation.
- Added project changelog and roadmap.

### Validation

- All project shell scripts pass syntax validation.
- ShellCheck passes across the project.
- `wdt doctor` integration test passes.
- Project test suite reports 20 passed and 0 failed.
- Git working tree remains clean after committed milestones.
