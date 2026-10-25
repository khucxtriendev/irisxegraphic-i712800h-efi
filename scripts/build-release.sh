#!/bin/bash
# Rebuild local artifacts only. Does not install drivers or write a boot volume.
set -euo pipefail
task_root="$(cd "$(dirname "$0")/.." && pwd)"
task_stock="${1:?Usage: build-release.sh /path/to/stock/sle}"
cd "$task_root"
bash source-review/check-cpu.sh > reports/cpu-checks-release.log 2>&1
python3 source-review/install-check.py > reports/install-checks.log 2>&1
zsh vendor/iris-xe/build-nootedgreen.sh > reports/build-nootedgreen.log 2>&1
bash scripts/build-userland.sh "$task_stock" > reports/build-userland.log 2>&1
python3 scripts/make-usb-map.py
python3 scripts/make-configs.py
python3 - <<'PY'
from pathlib import Path
import shutil
root = Path.cwd()
destination = root / 'EFI/OC/Kexts/NootedGreen.kext'
shutil.rmtree(destination)
shutil.copytree(root / 'vendor/iris-xe/build/NootedGreen.kext', destination)
PY
codesign --verify --deep --strict EFI/OC/Kexts/NootedGreen.kext
codesign --verify --deep --strict build/userland/AppleIntelTGLGraphicsMTLDriver.bundle
codesign --verify --deep --strict build/userland/xe.bundle
python3 scripts/validate.py
python3 scripts/record-build.py
python3 scripts/package-release.py "${2:-P1-Gen5-20261025-r2}"
