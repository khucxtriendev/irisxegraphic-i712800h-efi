#!/bin/bash
# Run manually; installs both graphics components with backups and rollback.
set -euo pipefail
task_script_dir="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$task_script_dir/cai_dat_nhanh.py" "$@"
