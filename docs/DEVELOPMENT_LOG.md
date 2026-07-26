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
